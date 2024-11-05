from flask import Flask, request, jsonify
from threading import Lock
import json
import time
import threading

app = Flask(__name__)

room_init = open

user_timeout = 5

interval = 1


with open("./init/rooms.json", "r") as file:
    defs = json.load(file)["defs"]
    for room in defs:
        room_file = open(f"data/rooms/{room['room_id']}.json", "w")
        base_room_data = {
            "room_id": room["room_id"],
            "room_name": room["room_name"],
            "maps": room["maps"],
            "users": {},
        }
        print(base_room_data)
        room_file.write(json.dumps(base_room_data, indent=4))

# Room data structure with a thread lock for concurrency safety
# rooms = {"room_id": 1, "room_name": "Room 1", "users": []}
# rooms_lock = Lock()


def write_user_to_room(room_id, user):
    room_file = open(f"data/rooms/{room_id}.json", "r")
    room_data = json.load(room_file)

    user_name = user["name"]
    del user["name"]

    user["timestamp"] = time.time()

    room_data["users"][user_name] = user

    room_file.close()

    room_file = open(f"data/rooms/{room_id}.json", "w")
    room_file.write(json.dumps(room_data, indent=4))

    return room_data


# Endpoint to join/update position in a room
@app.route("/rooms/<room_id>/update", methods=["POST"])
def update_room(room_id):
    # TODO: Implement this endpoint
    room_json = write_user_to_room(room_id, request.json)
    print(room_json)
    return jsonify(json.dumps(room_json["users"])), 501


@app.route("/rooms/<room_id>", methods=["GET"])
def get_room(room_id):
    file = open(f"data/rooms/{room_id}.json", "r")
    return json.load(file)


def myPeriodicFunction():
    for room_id in ["1", "2", "3"]:
        room_file = open(f"data/rooms/{room_id}.json", "r")
        room_data = json.load(room_file)

        current_timestamp = time.time()

        shitlist = []

        for user_name in room_data["users"]:
            diff = current_timestamp - room_data["users"][user_name]["timestamp"]
            if diff >= user_timeout:
                print(diff)
                shitlist.append(user_name)

        if len(shitlist) > 0:
            print(shitlist)

        for user_name in shitlist:
            del room_data["users"][user_name]

        room_file.close()

        room_file = open(f"data/rooms/{room_id}.json", "w")
        room_file.write(json.dumps(room_data, indent=4))


def startTimer():
    threading.Timer(interval, startTimer).start()
    myPeriodicFunction()


startTimer()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
