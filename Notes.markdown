# Game

- Server:
  Starts a listen socket
  Listens for join requests
  On join request, add remote addr to client list
    - Join request includes ship configuration
    - For each remote remember last N movements

  Start a write socket for each joiner
    - Once per N seconds use last N movements to cal board state
    - Record collisisons
    - Write new board config to clients
      - Board config: Client config, colision status, xy-coords

- Clients:
  Update the server of movement request
  Update their board based on server info
    - Colorize if colision with self

