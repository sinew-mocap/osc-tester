// Minimal C FFI for the Lean OSC tester: float32 bit-pattern, float parsing, and
// a one-shot UDP datagram send.  Lean 4 has no sockets and only Float64, so these
// three primitives are all the native code the tester needs.
#include <lean/lean.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// Float64 -> the raw 32-bit IEEE-754 pattern of the nearest Float32 (OSC 'f').
uint32_t lean_osc_float32_bits(double d) {
    float f = (float)d;
    uint32_t bits;
    memcpy(&bits, &f, sizeof(bits));
    return bits;
}

// Parse a decimal string to Float64 (Lean core has no String->Float).
double lean_osc_parse_float(b_lean_obj_arg s) {
    return strtod(lean_string_cstr(s), NULL);
}

// Send `data` as a single UDP datagram to host:port.  IO Unit; throws on failure.
lean_obj_res lean_osc_udp_send(b_lean_obj_arg host, uint32_t port,
                               b_lean_obj_arg data, lean_obj_arg world) {
    (void)world;
    const char *h = lean_string_cstr(host);
    size_t len = lean_sarray_size(data);
    const uint8_t *buf = lean_sarray_cptr(data);

    int fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (fd < 0)
        return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("socket() failed")));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons((uint16_t)port);
    if (inet_pton(AF_INET, h, &addr.sin_addr) != 1) {
        close(fd);
        return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("bad host address")));
    }

    ssize_t n = sendto(fd, buf, len, 0, (struct sockaddr *)&addr, sizeof(addr));
    close(fd);
    if (n != (ssize_t)len)
        return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string("sendto() failed")));

    return lean_io_result_mk_ok(lean_box(0));
}
