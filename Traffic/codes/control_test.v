module control_test;
    reg clk, rst;
    reg Emergency_left, Emergency_right;
    wire T1_Red, T1_Green, T1_Yellow, T1_Orange, T1_Right;
    wire T2_Red, T2_Green, T2_Yellow, T2_Orange, T2_Left;
    wire T1_WALK, T2_WALK, Buzzer_Walk;
    wire emergency;
    wire [3:0] emergency_timer;

    // Instantiate DUT
    Traffic_Controller uut (
        .clk(clk),
        .rst(rst),
        .Emergency_left(Emergency_left),
        .Emergency_right(Emergency_right),
        .T1_Red(T1_Red), .T1_Green(T1_Green), .T1_Yellow(T1_Yellow), .T1_Orange(T1_Orange), .T1_Right(T1_Right),
        .T2_Red(T2_Red), .T2_Green(T2_Green), .T2_Yellow(T2_Yellow), .T2_Orange(T2_Orange), .T2_Left(T2_Left),
        .T1_WALK(T1_WALK), .T2_WALK(T2_WALK), .Buzzer_Walk(Buzzer_Walk)
    );
    assign emergency        = uut.emergency;
    assign emergency_timer  = uut.emergency_timer;

    // Dump waveform
    initial begin
        $dumpfile("control_test.vcd");
        $dumpvars(0, control_test);
    end

    // Clock generation: 1s period
    initial clk = 0;
    always #0.5 clk = ~clk;

    initial begin
        // Initialize
        rst = 1; Emergency_left = 0; Emergency_right = 0;
        #1 rst = 0;

        // Normal operation
        #50;

        // Emergency left active
        Emergency_left = 1;
        #10 Emergency_left = 0;

        #50;

        // Emergency right active
        Emergency_right = 1;
        #20 Emergency_right = 0;

        // Continue running to observe recovery
        #600;

        $finish;
    end

    // Monitor all relevant outputs every positive clock edge
    always @(posedge clk) begin
        $display("T=%0t | EL=%b ER=%b | T1:R=%b G=%b Y=%b O=%b RGT=%b | T2:R=%b G=%b Y=%b O=%b LFT=%b | WALK:T1=%b T2=%b | BZ=%b | EM=%b ET=%0d", 
                 $time, Emergency_left, Emergency_right,
                 T1_Red, T1_Green, T1_Yellow, T1_Orange, T1_Right,
                 T2_Red, T2_Green, T2_Yellow, T2_Orange, T2_Left,
                 T1_WALK, T2_WALK, Buzzer_Walk,
                 emergency, emergency_timer);
    end
endmodule

