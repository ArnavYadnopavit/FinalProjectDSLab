`timescale 1s / 1ms

module test;
  reg        clk, reset;
  reg        mode_btn, add_hour, add_minute;
  reg        set_timer_btn, set_alarm_btn;
  reg        AM_mode;
  wire [5:0] sec, min, hr, timer_min_left, timer_sec_left;
  wire       AM_PM, timer_buzzer, alarm_buzzer;
  wire [4:0] day;
  wire [3:0] month;
  wire [11:0] year;

  the_clock uut(
    .clk(clk), .reset(reset),
    .mode_btn(mode_btn),
    .add_hour(add_hour), .add_minute(add_minute),
    .set_timer_btn(set_timer_btn),
    .set_alarm_btn(set_alarm_btn),
    .AM_mode(AM_mode),
    .sec(sec), .min(min), .hr(hr), .AM_PM(AM_PM),
    .day(day), .month(month), .year(year),
    .timer_buzzer(timer_buzzer),
    .alarm_buzzer(alarm_buzzer),
    .timer_min_left(timer_min_left),
    .timer_sec_left(timer_sec_left)
  );
integer i,j;
  initial begin
    // dump waves
    //$dumpfile("datetest.vcd");
    //$dumpvars(0,test);

    // initialize
    clk            = 0;
    reset          = 1;
    AM_mode        = 1;
    mode_btn       = 0;
    add_hour       = 0;
    add_minute     = 0;
    set_timer_btn  = 0;
    set_alarm_btn  = 0;
    #1 reset = 0;

    // IDLE
   for (j = 0; j < 1947+1; j = j + 1) begin //j is number of days we want till april so j= 366*2+365*3+31+28+31+30=1947
  for (i = 0; i < 23; i = i + 1) begin
    #1 add_hour = 1; 
    #1 add_hour = 0;  // +1 hour
    #1 add_minute = 1; 
    #1 add_minute = 0;  // +1 minute
  end
  for (i = 0; i < 35; i = i + 1) begin
    #1 add_minute = 1; 
    #1 add_minute = 0;  // +1 minute
  end
  #23;
  end
  


    $finish;
  end

  // 0.5s clock
  always #0.5 clk = ~clk;

  // display
  always @(posedge clk) begin
    $display("MODE=%0d | %02d:%02d:%02d %s | %02d/%02d/%04d | Tleft=%02d:%02d Bz=%b | Albz=%b",
      uut.state,
      hr, min, sec, AM_mode?(AM_PM ? "PM" : "AM"):"HOURS",
      day, month, year,
      timer_min_left, timer_sec_left, timer_buzzer,
      alarm_buzzer
    );
  end

endmodule

