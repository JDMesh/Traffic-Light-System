`timescale 1ns/1ps

module traffic_light_top (
    input clk,           // 50MHz clock (Pin E3)
    input rst_btn,       // Active LOW reset (Pin A6)
    output reg RED1,     // Pin 3
    output reg GREEN1,   // Pin 2
    output reg YELLOW1,  // Pin 141
    output reg RED2,     // Pin 1
    output reg GREEN2,   // Pin 136
    output [6:0] seg,    // 7-segment segments (a-g)
    output [3:0] dig     // 7-segment digit select (DIG1-DIG4)
);

// Clock dividers
reg [31:0] clk_div_traffic;  // For 100Hz traffic light
reg [31:0] clk_div_sec;      // For 1Hz seconds counter
reg [31:0] clk_div_seg;      // For 1kHz 7-segment scan

reg clk_100hz;
reg clk_1hz;
reg clk_1khz;

// Traffic light state machine
reg [2:0] state;
reg [5:0] seconds;  // 0-59 seconds
reg [1:0] digit_select;

// Active LOW reset
wire rst = ~rst_btn;

// =============================================
// Clock Dividers
// =============================================

// 50MHz -> 100Hz (period = 500,000 cycles / 2 = 250,000)
always @(posedge clk or posedge rst) begin
    if (rst)
        clk_div_traffic <= 0;
    else if (clk_div_traffic >= 249_999)  // 500k / 2
        clk_div_traffic <= 0;
    else
        clk_div_traffic <= clk_div_traffic + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        clk_100hz <= 0;
    else if (clk_div_traffic == 0)
        clk_100hz <= ~clk_100hz;
end

// 50MHz -> 1Hz (period = 50,000,000 cycles / 2 = 25,000,000)
always @(posedge clk or posedge rst) begin
    if (rst)
        clk_div_sec <= 0;
    else if (clk_div_sec >= 24_999_999)  // 50M / 2
        clk_div_sec <= 0;
    else
        clk_div_sec <= clk_div_sec + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        clk_1hz <= 0;
    else if (clk_div_sec == 0)
        clk_1hz <= ~clk_1hz;
end

// 50MHz -> 1kHz (period = 50,000 cycles / 2 = 25,000)
always @(posedge clk or posedge rst) begin
    if (rst)
        clk_div_seg <= 0;
    else if (clk_div_seg >= 24_999)  // 50k / 2
        clk_div_seg <= 0;
    else
        clk_div_seg <= clk_div_seg + 1;
end

always @(posedge clk or posedge rst) begin
    if (rst)
        clk_1khz <= 0;
    else if (clk_div_seg == 0)
        clk_1khz <= ~clk_1khz;
end

// =============================================
// Traffic Light State Machine (100Hz)
// =============================================

always @(posedge clk_100hz or posedge rst) begin
    if (rst)
        state <= 3'b000;
    else
        state <= state + 1;
end

// State decode (combinational)
always @(*) begin
    case (state)
        // Direction 1: RED (3 states) -> YELLOW (1 state) -> GREEN (3 states)
        3'b000: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b10001;  // DIR1: RED, DIR2: GREEN
        3'b001: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b10001;  // DIR1: RED, DIR2: GREEN
        3'b010: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b10001;  // DIR1: RED, DIR2: GREEN
        3'b011: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b00100;  // DIR1: YELLOW, DIR2: YELLOW
        3'b100: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b01010;  // DIR1: GREEN, DIR2: RED
        3'b101: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b01010;  // DIR1: GREEN, DIR2: RED
        3'b110: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b01010;  // DIR1: GREEN, DIR2: RED
        3'b111: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b00100;  // DIR1: YELLOW, DIR2: YELLOW
        default: {RED1, GREEN1, YELLOW1, RED2, GREEN2} = 5'b10001;
    endcase
end

// =============================================
// Seconds Counter (1Hz)
// =============================================

always @(posedge clk_1hz or posedge rst) begin
    if (rst)
        seconds <= 0;
    else if (seconds >= 59)
        seconds <= 0;
    else
        seconds <= seconds + 1;
end

// =============================================
// 7-Segment Display Multiplexing (1kHz)
// =============================================

reg [3:0] digit_tens;
reg [3:0] digit_ones;
reg [3:0] current_digit;

always @(posedge clk_1khz or posedge rst) begin
    if (rst)
        digit_select <= 0;
    else
        digit_select <= digit_select + 1;
end

// Split seconds into tens and ones
always @(*) begin
    digit_tens = seconds / 10;
    digit_ones = seconds % 10;
end

// Select which digit to display
always @(*) begin
    case (digit_select)
        2'b00: current_digit = digit_tens;   // DIG1 (tens)
        2'b01: current_digit = digit_ones;   // DIG2 (ones)
        2'b10: current_digit = 4'b0000;      // DIG3 (unused)
        2'b11: current_digit = 4'b0000;      // DIG4 (unused)
        default: current_digit = 4'b0000;
    endcase
end

// 7-segment decoder (Common Anode: 0 = LED ON)
reg [6:0] seg_data;
always @(*) begin
    case (current_digit)
        4'd0: seg_data = 7'b0000001;  // 0
        4'd1: seg_data = 7'b1001111;  // 1
        4'd2: seg_data = 7'b0010010;  // 2
        4'd3: seg_data = 7'b0000110;  // 3
        4'd4: seg_data = 7'b1001100;  // 4
        4'd5: seg_data = 7'b0100100;  // 5
        4'd6: seg_data = 7'b0100000;  // 6
        4'd7: seg_data = 7'b0001111;  // 7
        4'd8: seg_data = 7'b0000000;  // 8
        4'd9: seg_data = 7'b0000100;  // 9
        default: seg_data = 7'b1111111; // All OFF
    endcase
end

// Digit select output (Common Anode: 1 = digit ON)
assign dig = ~(4'b0001 << digit_select);
assign seg = seg_data;

endmodule