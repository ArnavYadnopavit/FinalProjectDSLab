`timescale 1s / 1ms

module test;
    reg clk;
    reg reset;
    reg AM_mode;
    reg set_timer;
    reg [3:0] timer_minutes;
    reg set_alarm;
    reg [5:0] alarm_hr;
    reg [5:0] alarm_min;
    reg add_hour;
    reg add_minute;


    wire [5:0] sec;
    wire [5:0] min;
    wire [5:0] hr;
    wire AM_PM;
    wire [4:0] day;
    wire [3:0] month;
    wire [11:0] year;
    wire timer_buzzer;
    wire alarm_buzzer;
    wire [5:0] timer_min_left;
    wire [5:0] timer_sec_left;

    digital_clock uut (
        .clk(clk), .reset(reset), .AM_mode(AM_mode),
        .set_timer(set_timer), .timer_minutes(timer_minutes),
        .set_alarm(set_alarm), .alarm_hr(alarm_hr), .alarm_min(alarm_min),
        .sec(sec), .min(min), .hr(hr), .AM_PM(AM_PM),.add_hour(add_hour),.add_minute(add_minute),
        .day(day), .month(month), .year(year),
        .timer_buzzer(timer_buzzer), .alarm_buzzer(alarm_buzzer),
        .timer_min_left(timer_min_left), .timer_sec_left(timer_sec_left)
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);

        clk = 0;
        reset = 1;
        AM_mode = 1; // 12-hour mode
        set_timer = 0;
        timer_minutes = 4'd1; // 1 minute timer
        set_alarm = 0;
        alarm_hr = 6'd12;
        alarm_min = 6'd1;

        #2 reset = 0;

        // Set the timer after reset
        #2 set_timer = 1;
        #2 set_timer = 0;

        // Set an alarm
        #5 set_alarm = 1;
        #2 set_alarm = 0;

        // Simulate for some time
        #300
        
add_minute = 1;
    #1  add_minute = 0;
    #1 add_hour = 1;#24
    add_hour=0;
    #3400
    AM_mode=0;
    #36000
    reset=1;#1
    reset=0;#1
    
     $finish;
    end

    always begin
        #0.5 clk = ~clk;
    end

    always @(posedge clk) begin
        $display("Time: %02d:%02d:%02d %s | Date: %02d/%02d/%04d | Timer Left: %02d:%02d | Timer Buzzer: %b | Alarm Buzzer: %b",
                 hr, min, sec, AM_mode?(AM_PM ? "PM" : "AM"):"HOURS", day, month, year,
                 timer_min_left, timer_sec_left, timer_buzzer, alarm_buzzer);
    end
endmodule
