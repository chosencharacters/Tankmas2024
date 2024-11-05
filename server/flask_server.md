
# Setting Up a Flask Server for an Online Game on Ubuntu Server

## Prerequisites

### Ubuntu 20+

### Python: Ensure Python 3 is installed on your system.
```sudo apt update```
```sudo apt install python3```

### Flask: Install Flask using pip.
```pip install Flask```

## Ubuntu Server Setup

1. Connect to Your Server
	Use SSH to connect to your Ubuntu server.
	```ssh your_username@your_server_ip```

2. Create a Project Directory
	Create a directory for your Flask app, e.g., flask_game_server, and navigate into it.
	```mkdir flask_game_server```
	```cd flask_game_server```

3. Create the Flask Application File
	Create a new file named app.py
	```sudo nano app.py```
	Paste the Flask code below into app.py and save it.
    
4. Run the Server
	Start the Flask server:
	```python3 app.py```

5. Open port 5000 in your firewall to allow access:
	```sudo ufw allow 5000```

6. Optional: Running Flask with Gunicorn
	Install Gunicorn for a production-grade server:
	```pip install gunicorn```

	Run your app using Gunicorn:
	```gunicorn --bind 0.0.0.0:5000 app:app```