import std.stdio;
import std.concurrency;
import std.socket;
import std.datetime;
import core.thread;
import std.typecons;
import std.conv;

import udpio;
import udpnames;

alias TickDuration.from tdur;

void listen(Tid tid, immutable InternetAddress inet, string username) {
  Socket connection = new UdpSocket();
  connection.setOption(SocketOptionLevel.SOCKET, SocketOption.RCVTIMEO, dur!"msecs"(20));
  connection.blocking = false;

  byte[2] header = [cast(byte)0xFF, cast(byte)0xFF];

  writeln("binding");
  connection.bind(new InternetAddress(InternetAddress.PORT_ANY));

  byte[1000] buffer;

  TickDuration d = sendUdpMessage(header ~ UDP.ping, header ~ UDP.ping, buffer, connection, inet, tdur!"seconds"(5), tdur!"seconds"(11));

  writeln("ping: ", d.msecs);

  d = sendUdpMessage(header ~ UDP.connect ~ writeString(username), header ~ UDP.connect, buffer, connection, inet, tdur!"seconds"(2), tdur!"seconds"(1));
  if (d.seconds != -1 && buffer[3] != -1) writeln("connected");
  else {
    writeln("failed to connect to server");
    send(tid, UDP.disconnect, 1);
    return;
  }
  send(tid, UDP.connect, buffer[3], username);
  byte playerID = buffer[3];
  scope(exit) {
    if (!disconnect) {
      writeln("Sending Disconnect.");
      d = sendUdpMessage(header ~ UDP.disconnect, header ~ UDP.disconnect, buffer, connection, inet, tdur!"seconds"(1), tdur!"seconds"(3));
      if (!quit)
        send(tid, UDP.disconnect, 1);
    }
  }

  connection.sendTo(header ~ [to!byte(UDP.map), to!byte(-1)], inet);

  byte[][] receivedPackets;

  StopWatch sw = StopWatch(AutoStart.yes);

  bool resent = false;
  bool received = false;
  while(sw.peek.msecs < 3000 && !received) {
    Address address;
    buffer[] = 0;
    long result = connection.receiveFrom(buffer, address);
    if (result != Socket.ERROR && result != 0) {
      if (buffer[0..2] != header) continue;
      if (address.toAddrString != inet.toAddrString) continue;
      //writeln(buffer);
      if (buffer[2] != UDP.map) continue;
      sw.stop;
      sw.reset;
      sw.start;
      resent = false;
      if (buffer[3] == -1) {
        receivedPackets.length = buffer[4];
      } else {
        if (receivedPackets.length == 0) continue;
        receivedPackets[buffer[3]] = buffer[4..$].dup;
        foreach (i, packet; receivedPackets) {
          if (packet.length == 0) break;
          if (i == receivedPackets.length - 1) received = true;
        }
      }
    }
    if (!resent && sw.peek.msecs > 2000) {
      byte[] resend;
      if (receivedPackets.length == 0) resend ~= -1;
      foreach (i, packet; receivedPackets) {
        if (packet.length == 0) resend ~= to!byte(i);
      }
      writeln(resend);
      foreach (i; resend) {
        connection.sendTo(header ~ [to!byte(UDP.map), i], inet);
      }
      resent = true;
    }
  }

  bool failed = false;

  if (receivedPackets.length == 0) failed = true;
  foreach (packet; receivedPackets) {
    if (packet.length == 0) failed = true;
  }

  if (failed) {
    writeln("Failed to receive map");
    return;
  }

  byte[] map;

  foreach (packet; receivedPackets) {
    map ~= packet;
  }

  send(tid, map.idup);

  connection.sendTo(header ~ [to!byte(UDP.player_list), playerID], inet);

  writeln("running");
  sw = StopWatch(AutoStart.yes);

  long lastMessage = sw.peek.msecs;

  bool running = true;
  bool disconnect = false;
  bool quit = false;

  while(running) {
    try{receiveTimeout(dur!"msecs"(1), (bool stop) {running = false; quit = true;},
                       (immutable(byte)[] packet) {connection.sendTo(header ~ packet, inet);});
    } catch (Exception e) {
      writeln(e);
    }
    Address address;
    buffer[] = 0;
    if (!running) break;
    long result = connection.receiveFrom(buffer, address);
    if (result != Socket.ERROR && result != 0) {
      if (buffer[0..2] != header) continue;
      if (address.toAddrString != inet.toAddrString) continue;
      byte[] data;
      //writeln(buffer);
      sw.stop();
      lastMessage = sw.peek.msecs;
      sw.start();
      uint index = 2;
      //writeln("received data: ", address);
      while(index < buffer.length && buffer[index] != 0) {
        //writeln("index = ", index);
        switch (buffer[index]) {
          case UDP.movement: 
            UDP type = cast(UDP)buffer[index++];
            byte player = buffer[index++];
            Tuple!(float, float) pos = tuple(readFloat(buffer, index), readFloat(buffer, index));
            Tuple!(float, float) vel = tuple(readFloat(buffer, index), readFloat(buffer, index));
            send(tid, type, player, pos, vel);
            break;
          case UDP.die: case UDP.respawn:
            UDP type = cast(UDP)buffer[index++];
            byte player = buffer[index++];
            send(tid, type, player);
            break;
          case UDP.fire_shot:
            UDP type = cast(UDP)buffer[index++];
            int player = readInt(buffer, index);
            Tuple!(float, float) pos = tuple(readFloat(buffer, index), readFloat(buffer, index));
            Tuple!(float, float) vel = tuple(readFloat(buffer, index), readFloat(buffer, index));
            send(tid, type, player, pos, vel);
            break;
          case UDP.fire_ninja_rope:
            UDP type = cast(UDP)buffer[index++];
            int player = readInt(buffer, index);
            Tuple!(float, float) pos = tuple(readFloat(buffer, index), readFloat(buffer, index));
            Tuple!(float, float) vel = tuple(readFloat(buffer, index), readFloat(buffer, index));
            send(tid, type, player, pos, vel);
            break;
          case UDP.disconnect_ninja_rope:
            int player = readInt(buffer, ++index);
            send(tid, UDP.disconnect_ninja_rope, player);
            break;
          case UDP.disconnect:
            running = false;
            index = buffer.length;
            break;
          case UDP.damage:
            index++;
            int damage = readInt(buffer, index);
            //writeln("damage: ", damage);
            send(tid, UDP.damage, damage);
            index++;
            break;
          case UDP.player:
            index+= 2;
            byte id = buffer[index - 1];
            Tuple!(float, float) pos = tuple(readFloat(buffer, index), readFloat(buffer, index));
            Tuple!(float, float) vel = tuple(readFloat(buffer, index), readFloat(buffer, index));
            send(tid, UDP.player, id, pos, vel);
            break;
          case UDP.player_list:
            index++;
            int numPlayers = buffer[index++];
            int[] ids;
            string[] usernames;

            foreach (i; 0..numPlayers) {
              ids ~= buffer[index++];
              usernames ~= readString(buffer, index);
            }

            send(tid, UDP.player_list, ids.idup, usernames.idup);
            break;
          default:
            index++;
            break;
        }
      }
    }
    if (sw.peek.msecs - lastMessage > 5000) {
      send(tid, UDP.disconnect, 1);
      disconnect = true;
      running = false;
    }
  }
}

TickDuration sendUdpMessage(byte[] message, byte[] responseHeader, out byte[1000] buffer, Socket connection,
  immutable InternetAddress inet, TickDuration timeout = tdur!"seconds"(1), TickDuration resend = tdur!"seconds"(1)) {
  connection.sendTo(message, inet);
  StopWatch sw = StopWatch(AutoStart.yes);
  Address ASender;
  InternetAddress IASender;
  bool received = false;
  TickDuration ping;
  while (received == false) {
    sw.stop();
    if (sw.peek + ping > timeout) {
      ping = tdur!"seconds"(-1);
      break;
    }
    if (sw.peek > resend) {
      connection.sendTo(message, inet);
      ping += sw.peek;
      sw.reset();
    }
    sw.start();
    long result = connection.receiveFrom(buffer, ASender);
    if (result == 0 || result == Socket.ERROR) continue;
    //writeln("received Packet");
    IASender = cast(InternetAddress)ASender;
    if (IASender.addr != inet.addr) continue;
    //writeln(buffer, " ", responseHeader);
    if (buffer[0..responseHeader.length] != responseHeader[]) continue;
    received = true;
  }
  sw.stop();
  if (ping.seconds == -1) {
    buffer[] = 0;
    return ping;
  }

  ping += sw.peek;
  return ping;
}