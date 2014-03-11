//---------------------------------------------------------
// Buffered NeoPixel driver
// by teachop
//

#include <xs1.h>
#include <timer.h>
#include <stdint.h>


// length of the strip(s)
#define LEDS 60


// ------------------------------------------------------------
// grbColor - convert separate R,G,B into a neopixel color word
//
uint32_t grbColor(uint8_t r, uint8_t g, uint8_t b) {
    return ((uint32_t)g << 16) | ((uint32_t)r <<  8) | b;
}


// ---------------------------------------------------------
// wheel - input a value 0 to 255 to get a color value.
//         The colors are a transition r - g - b - back to r
//
uint32_t wheel(uint8_t wheelPos) {
    if ( wheelPos < 85 ) {
        return grbColor(wheelPos * 3, 255 - wheelPos * 3, 0);
    } else if ( wheelPos < 170 ) {
        wheelPos -= 85;
        return grbColor(255 - wheelPos * 3, 0, wheelPos * 3);
    } else {
        wheelPos -= 170;
        return grbColor(0, wheelPos * 3, 255 - wheelPos * 3);
    }
}


// ---------------------------------------------------------
// neopixel_led_driver - output driver for one neopixel strip
//
void neopixel_led_driver(port neo, uint32_t (&colors)[]) {
    const uint32_t delay_third = 42;
    uint32_t delay_count;
    uint32_t bit;

    // beginning of strip, resync counter
    neo <: 0 @ delay_count;
    delay_count += delay_third;

    for ( uint32_t pixel=0; pixel<LEDS; ++pixel ) {
        uint32_t color_shift = colors[pixel];
        uint32_t bit_count = 24;
        while (bit_count--) {
            // output low->high transition
            delay_count += delay_third;
            neo @ delay_count <: 1;

            // output high->data transition
            bit = (color_shift & 0x800000)? 1 : 0;
            color_shift <<=1;
            delay_count += delay_third;
            neo @ delay_count <: bit;

            // output data->low transition
            delay_count += delay_third;
            neo @ delay_count <: 0;
        }
    }

}


// ---------------------------------------------------------------
// blinky_task - rainbow cycle pattern from pjrc and / or adafruit
//
void blinky_task(port neo, uint32_t strip) {
    uint32_t colors[LEDS];
    timer tick;
    uint32_t next_pass;

    while (1) {
        for ( uint32_t outer=0; outer<256; ++outer) {
            // cycle of all colors on wheel
            for ( uint32_t loop=0; loop<LEDS; ++loop) {
                colors[loop] = wheel(( (loop*256/LEDS) + outer) & 255);
            }

            // write to the strip
            neopixel_led_driver(neo, colors);

            // wait a bit, must allow strip to latch at least
            tick :> next_pass;
            next_pass += (50+strip*500)*100;
            tick when timerafter(next_pass) :> void;
        }
    }
}


// ---------------------------------------------------------
// main - xCore startKIT NeoPixel blinky test
//
port out_pin[8] = {
    // j7.1, j7.2, j7.3, j7.4, j7.23, j7.21, j7.20, j7.19
    XS1_PORT_1F, XS1_PORT_1H, XS1_PORT_1G, XS1_PORT_1E,
    XS1_PORT_1P, XS1_PORT_1O, XS1_PORT_1I, XS1_PORT_1L
};
int main() {

    par {
        // 8 tasks, 8 cores, drive 8 led strips with differing patterns
        blinky_task(out_pin[0], 0);
        blinky_task(out_pin[1], 1);
        blinky_task(out_pin[2], 2);
        blinky_task(out_pin[3], 3);
        blinky_task(out_pin[4], 4);
        blinky_task(out_pin[5], 5);
        blinky_task(out_pin[6], 6);
        blinky_task(out_pin[7], 7);
    }

    return 0;
}

