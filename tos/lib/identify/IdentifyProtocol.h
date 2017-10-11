#ifndef IDENTIFYPROTOCOL_H_
#define IDENTIFYPROTOCOL_H_

#define AMID_IDENTIFY_PROTOCOL 0xEF

#define IDFY_VERSION 0x02 // Version 0.2

enum IdentifyProtocolHeaders {
	IDFY_HEADER_STATUS  = 0x01,
	IDFY_HEADER_CONTROL = 0x02,
	IDFY_HEADER_REPORT  = 0x10,
	IDFY_HEADER_ERROR   = 0xFF
};

typedef nx_struct {
	nx_uint8_t version;  // version is a MAJOR.MINOR 4bit.4bit value
	nx_uint8_t header;   // packet type identifier
	nx_uint8_t auth[16]; // authorization token / password
	nx_uint8_t value;    // requested ifentify action / value
	nx_uint32_t period;  // identify action period, milliseconds
} idfy_control_msg_t;

typedef nx_struct {
	nx_uint8_t version; // version is a MAJOR.MINOR 4bit.4bit value
	nx_uint8_t header;  // packet type identifier
} idfy_request_msg_t;

typedef nx_struct {
	nx_uint8_t version;    // version is a MAJOR.MINOR 4bit.4bit value
	nx_uint8_t header;     // packet type identifier
	nx_uint8_t value;      // current identify value
	nx_uint32_t remaining; // remaining milliseconds of the identify action
} idfy_status_msg_t;

typedef nx_struct {
	nx_uint8_t version; // version is a MAJOR.MINOR 4bit.4bit value
	nx_uint8_t header;  // packet type identifier
	nx_uint8_t code;    // error code
	nx_uint8_t msg_len; // error message length
	nx_uint8_t msg[];   // error message string
} idfy_error_msg_t;

enum IdentifyProtocolErrors {
	IDFY_ERROR_NONE         = 0,
	IDFY_ERROR_GENERIC      = 1,
	IDFY_ERROR_VERSION      = 2,
	IDFY_ERROR_UNAUTHORIZED = 3,
	IDFY_ERROR_PACKET       = 4
};

#endif // IDENTIFYPROTOCOL_H_
