import std.stdio;
import std.socket;
import std.datetime;
import std.algorithm;
import std.concurrency;
import std.typecons;
import std.conv;

import udpnames;
import udpio;

void listen(Tid tid, uint maxPlayers) {
  ushort port = 19863;
  Socket listener = new UdpSocket();
  listener.blocking = false;

  listener.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, dur!"msecs"(16));

  listener.bind(new InternetAddress(port));

  scope(failure) { writeln("Uh Oh"); }
  scope(success) { writeln("Exit"); }

  byte[1000] buffer;
  byte[2] header = [cast(byte)0xFF, cast(byte)0xFF];

  Address[] clients;
  long[] lastMessageMsecs;
  string[] usernames;
  clients.length = maxPlayers;
  lastMessageMsecs.length = maxPlayers;
  usernames.length = maxPlayers;

  long currentTime;

  bool running = true;

  writeln("running");
  StopWatch sw = StopWatch(AutoStart.yes);
  while(running) {
    try{receiveTimeout(dur!"msecs"(1), (bool stop) {running = false;},
      (immutable(byte)[] packet, int id) { if (clients[id] !is null) listener.sendTo(header ~ packet, clients[id]);});

    } catch (Exception e) {
      writeln( e);
    }
    Address address;
    buffer[] = 0;
    long result = listener.receiveFrom(buffer, address);
    if (result != Socket.ERROR && result != 0) {
      if (buffer[0..2] != header) continue;
      byte[] data;
      //writeln(buffer);
      sw.stop();
      currentTime = sw.peek.msecs;
      sw.start();
      uint index = 2;
      //writeln("received data: ", address);
      bool AddrEqual(Address a, Address b) {if (a is null) return false; return a.toString == b.toString;}
      byte id = to!byte(countUntil!(AddrEqual)(clients, address));
      while(index < buffer.length && buffer[index] != 0) {
        //writeln("index = ", index);
        if (id != -1) {
          lastMessageMsecs[id] = currentTime;
          switch (buffer[index]) {
            case UDP.ping:
              data = [UDP.ping];
              listener.sendTo(header ~ data, address);
              index++;
              break;
            case UDP.movement:
              UDP type = cast(UDP)buffer[index++];
              byte player = buffer[index++];
              Tuple!(float, float) pos = tuple(readFloat(buffer, index), readFloat(buffer, index));
              Tuple!(float, float) vel = tuple(readFloat(buffer, index), readFloat(buffer, index));
              send(tid, type, to!int(player), pos, vel);
              break;
            case UDP.die: case UDP.respawn:
              UDP type = cast(UDP)buffer[index++];
              byte player = buffer[index++];
              send(tid, type, player);
              break;
            case UDP.fire_shot:
              UDP type = cast(UDP)buffer[index];
              index++;
              int player = readInt(buffer, index);
              //writeln("fire shot", player);
              Tuple!(float, float) pos = tuple(readFloat(buffer, index), readFloat(buffer, index));
              Tuple!(float, float) vel = tuple(readFloat(buffer, index), readFloat(buffer, index));
              send(tid, type, player, pos, vel);
              break;
            case UDP.fire_ninja_rope:
              UDP type = cast(UDP)buffer[index];
              index++;
              int player = readInt(buffer, index);
              Tuple!(float, float) pos = tuple(readFloat(buffer, index), readFloat(buffer, index));
              Tuple!(float, float) vel = tuple(readFloat(buffer, index), readFloat(buffer, index));
              send(tid, type, player, pos, vel);
              break;
            case UDP.disconnect_ninja_rope:
              index++;
              int player = readInt(buffer, index);
              send(tid, UDP.disconnect_ninja_rope, player);
              break;
            case UDP.disconnect:
              clients[id] = null;
              writeln(clients);
              data = [UDP.disconnect];
              listener.sendTo(header ~ data, address);
              send(tid, UDP.disconnect, id);
              index = buffer.length;
              break;
            case UDP.connect:
              data = UDP.connect ~ (id ~ writeString(usernames[id]));
              listener.sendTo(header ~ data, clients[id]);
              index++;
              readString(buffer, index);
              break;
            case UDP.map:
              writeln("map: ", buffer[index + 1]);
              index++;
              send(tid, UDP.map, id, buffer[index]);
              index++;
              break;
            case UDP.player_list:
              index++;
              send(tid, UDP.player_list, buffer[index++]);
              break;
            default:
              index++;
              break;
          }
        } else {
          switch (buffer[index]) {
            case UDP.ping:
              data = [UDP.ping];
              listener.sendTo(header ~ data, address);
              index++;
              break;
            case UDP.connect:
              index++;
              string username = readString(buffer, index);
              writeln(username);
              id = to!byte(countUntil!"a is b"(clients, null));
              if (id == -1) {
                data = [UDP.connect, -1];
                listener.sendTo(header ~ data, address);
              } else {
                data = [UDP.connect, id];
                listener.sendTo(header ~ data, address);
                clients[id] = address;
                lastMessageMsecs[id] = currentTime;
                usernames[id] = username;
                writeln(clients);
                send(tid, UDP.connect, id, username);
              }
              break;
            default:
              index++;
              break;
          }
        }
      }
    }
    sw.stop();
    currentTime = sw.peek.msecs;
    sw.start();
    foreach (id, client; clients) {
      if (client is null) continue;
      if (currentTime - lastMessageMsecs[id] > 7000) {
        clients[id] = null;
        send(tid, UDP.disconnect, id);
        writeln("disconnect: ", to!byte(id));
      }
    }
  }
}