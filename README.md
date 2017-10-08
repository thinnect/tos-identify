# README #

The identify protocol (IDFY) requests a node to somehow identify itself in the
physical world. This currently means lighting up or blinking a dedicated LED or
changing the behaviour of an LED that otherwise does something else.

### What is this repository for? ###

* TinyOS code for reacting to "identify" messages.
* Version 0.2

### Protocol ###

The IDFY protocol mainly consists of control and status messages. Control
messages are sent in order to get the target to perform the identify action.
The target respons with a status message that indicates the current status of
the identify action and the time remaining until the end of the current action.
Additionally it is possible to separately query the device for the current
of the identify activity.

#### Protocol version ####
Every IDFY packet starts with the protocol version byte. The version byte is
split into two 4-bit values, indicating the major and minor versions of the
protocol, semantic versioning principles are used. When a device receives a
packet from an incompatible version, then a version error response is sent.

#### Protocol authorization ####
Control messages need to contain an authorization value. This is a 16 byte
buffer, commonly used with string based human-readable passwords that are
terminated and padded until the end with \0 bytes. It is also possible to use
non-printable values, when using an authorization token or something similar.
Status requests do not require authorization and can also be used to discover
the protocol version of the device.

#### Protocol packets ####

See IdentifyProtocol.h for details and packet structures.

##### IDFY control #####
idfy_control_msg_t with header value 0x02.
Set value to 1 to start the IDFY action, set to 0 to stop an active IDFY.
Specify a time period in milliseconds for the action to take place. The time
period value is automatically corrected by the target if it is too short and
may be limited to some device specific maximum value.

##### IDFY request #####
idfy_request_msg_t with header value 0x01.
Allows the current status of the action to be requested.

##### IDFY status #####
idfy_status_msg_t with header value 0x10.
Includes the current state of the action (0 or 1) and time remaining if active.

#### Protocol errors ####
Protocol errors are reported with the idfy_error_msg_t packet with the header
value 0xFF. The packets contain an error code and optionally a human-readable
ASCII encoded message.

### Common use case ###
Send identify_control_msg_t with value 1 and time 60000 (60 seconds). Expect to
receive a response identify_status_msg_t with the value 1. Look around to
visually identify the device which is now behaving differently. Once the device
has been found, send identify_control_msg_t with value 0 and expect to receive
a response confirming that the action was stopped. If the stop command is not
sent, then the action stops after 60 seconds automatically.

Sending a control message with time 0 causes the identify module to perform the
shortest possible activity, but this may mean that visual identification is
possible only when looking at the device from the start. Maximum identify action
time is usually limited to 5 minutes.

### How do I get set up? ###

* Include the repository as a submodule.
* Include the tos/lib/identify folder.
* Include the tos/lib/indicators folder.
* Include IdentifyC in your TinyOS application.

### Who do I talk to? ###

* Raido Pahtma raido@thinnect.com
