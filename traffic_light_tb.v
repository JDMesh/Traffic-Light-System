`timescale 1ns/1ps

module traffic_light_tb;

reg clk;
reg rst_btn;

wire RED1;
wire GREEN1;
wire YELLOW1;
wire RED2;
wire GREEN2;
wire [6:0] seg;
wire [3:0] dig;

traffic_light_top uut (
    .clk(clk),
    .rst_btn(rst_btn),
    .RED1(RED1),
    .GREEN1(GREEN1),
    .YELLOW1(YELLOW1),
    .RED2(RED2),
    .GREEN2(GREEN2),
    .seg(seg),
    .dig(dig)
);

// 50MHz clock generator (20ns period)
always #10 clk = ~clk;

initial begin
    clk = 0;
    rst_btn = 0;  // Active LOW
    
    // Hold reset for 100ns
    #100 rst_btn = 1;
    
    // Run for 10 microseconds (enough to see multiple cycles)
    #10000;
    
    $finish;
end

initial begin
    $display("========================================");
    $display("Traffic Light & 7-Segment Display Test");
    $display("========================================");
    $display("Time (ns) | STATE | RED1 GRN1 YEL1 RED2 GRN2 | SEC | DIG[3:0]");
    $display("------------------------------------------------------------------");
    
    $monitor("%8t | %3b  |  %b    %b    %b    %b    %b   | %2d  | %b",
        $time,
        uut.state,
        RED1, GREEN1, YELLOW1, RED2, GREEN2,
        uut.seconds,
        dig
    );
end

// Optional: Generate waveform file for viewing in GTKWave
initial begin
    $dumpfile("traffic_light_tb.vcd");
    $dumpvars(0, traffic_light_tb);
end

endmodule