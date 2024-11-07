from flask import Flask, request, jsonify
from threading import Lock
import json
import time
import threading
import math

app = Flask(__name__)

room_init = open

user_max_idle_time = 9999999999999
base_client_tick_rate = 100
current_client_tick_rate = base_client_tick_rate

hits = 0
hits_attrition_rate = 5
hits_interval = 1
last_hits_update_time = 0

server_background_update_interval = 1

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
@app.route("/rooms/<room_id>/users", methods=["POST"])
def update_room(room_id):
    room_json = write_user_to_room(room_id, request.json)

    global hits
    hits = hits + 1

    package = {
        "tick_rate": current_client_tick_rate,
        "data": room_json["users"],
    }

    return jsonify(package), 200


@app.route("/rooms/<room_id>", methods=["GET"])
def get_room(room_id):
    file = open(f"data/rooms/{room_id}.json", "r")

    global hits
    hits = hits + 1

    package = {"tick_rate": current_client_tick_rate, "data": json.load(file)}
    return jsonify(package), 200


@app.route("/rooms/<room_id>/users", methods=["GET"])
def get_room_users(room_id):
    file = open(f"data/rooms/{room_id}.json", "r")

    global hits
    hits = hits + 1

    package = {"tick_rate": current_client_tick_rate, "data": json.load(file)}
    return jsonify(package), 200


def cleanup_old_users():
    for room_id in ["1", "2", "3"]:
        room_file = open(f"data/rooms/{room_id}.json", "r")
        room_data = json.load(room_file)

        current_timestamp = time.time()

        shitlist = []

        for user_name in room_data["users"]:
            diff = current_timestamp - room_data["users"][user_name]["timestamp"]
            if diff >= user_max_idle_time:
                shitlist.append(user_name)

        if len(shitlist) > 0:
            print(shitlist)

        for user_name in shitlist:
            del room_data["users"][user_name]

        room_file.close()

        room_file = open(f"data/rooms/{room_id}.json", "w")
        room_file.write(json.dumps(room_data, indent=4))


def server_background_tasks():
    threading.Timer(server_background_update_interval, server_background_tasks).start()
    cleanup_old_users()

    global last_hits_update_time
    global hits

    current_time = time.time()

    if current_time - last_hits_update_time >= hits_interval:
        attrition = math.floor(hits / hits_attrition_rate)
        if attrition < 1:
            attrition = 1
        current_client_tick_rate = base_client_tick_rate * attrition
        print(
            hits,
            current_client_tick_rate,
            math.floor(hits / hits_attrition_rate),
            attrition,
        )
        hits = 0
        last_hits_update_time = time.time()


server_background_tasks()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
