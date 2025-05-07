`timescale 1s / 1ms

module timekeeper(
    input clk,
    input reset,
    input AM_mode,
    input add_hour,
    input add_minute,
    output reg [5:0] sec,
    output reg [5:0] min,
    output reg [5:0] hr,
    output reg AM_PM,
    output reg [4:0] day,
    output reg [3:0] month,
    output reg [11:0] year
);

  // State encoding
  localparam S_SEC=2'd0,
             S_MIN=2'd1,
             S_HR=2'd2,
             S_DATE=2'd3;

  // State registers
  reg [1:0] state,next_state;

  // Next value registers
  reg [5:0] sec_next,min_next, hr_next;
  reg AM_PM_next;
  reg [4:0] day_next;
  reg [3:0] month_next;
  reg [11:0] year_next;
  reg [5:0] days_in_month;
  reg AM_mode_prev;

  // Sequential logic
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= S_SEC;
      sec <= 0;
      min <= 0;
      hr  <= 12;
      AM_PM <= 0;
      day <= 1;
      month <= 1;
      year <= 2020;
      AM_mode_prev <= AM_mode;
    end else begin
      state <= next_state;
      sec <= sec_next;
      min <= min_next;
      hr <= hr_next;
      AM_PM <= AM_PM_next;
      day <= day_next;
      month <= month_next;
      year <= year_next;
      AM_mode_prev <= AM_mode;
    end
  end

  //Combinational logic
  always @(*) begin
    next_state = state;
    sec_next = sec;
    min_next = min;
    hr_next = hr;
    AM_PM_next = AM_PM;
    day_next = day;
    month_next = month;
    year_next = year;

    //mode change
    if (AM_mode != AM_mode_prev) begin
      if (AM_mode) begin
        // 24h to 12h
        if (hr == 0) begin
          hr_next = 12;
          AM_PM_next = 0;
        end else if (hr == 12) begin
          hr_next = 12;
          AM_PM_next = 1;
        end else if (hr > 12) begin
          hr_next = hr - 12;
          AM_PM_next = 1;
        end else begin
          hr_next = hr;
          AM_PM_next = 0;
        end
      end else begin
        // 12h to 24h
        if (hr == 12 && AM_PM == 0)
          hr_next = 0;
        else if (hr == 12 && AM_PM == 1)
          hr_next = 12;
        else if (AM_PM == 1)
          hr_next = hr + 12;
        else
          hr_next = hr;
      end
    end

    // Main FSM
    case (state)
      S_SEC: begin
        if (sec == 6'd59) begin
          sec_next = 0;
          next_state = S_MIN;
        end else begin
          sec_next = sec + 1;
          next_state = S_SEC;
        end
      end

      S_MIN: begin
        if (min == 6'd59) begin
          min_next = 0;
          next_state = S_HR;
        end else begin
          min_next = min + 1;
          next_state = S_SEC;
        end
      end

      S_HR: begin
        if (AM_mode) begin
          if (hr == 6'd11) begin
            hr_next= 12;
            AM_PM_next = ~AM_PM;
          end else if (hr == 6'd12) begin
            hr_next = 1;
          end else begin
            hr_next = hr + 1;
          end
        end else begin
          if (hr == 6'd23)
            hr_next = 0;
          else
            hr_next = hr + 1;
        end
        next_state = S_DATE;
      end

      S_DATE: begin
        if ((AM_mode && hr_next == 12 && AM_PM_next == 0) ||(!AM_mode && hr_next == 0)) begin
          case (month)
            1, 3, 5, 7, 8, 10, 12: days_in_month = 31;
            4, 6, 9, 11:           days_in_month = 30;
            2: begin
              if ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
                days_in_month = 29;
              else
                days_in_month = 28;
            end
            default: days_in_month = 31;
          endcase
          if (day == 5'd30 && month == 4'd4 && year == 12'd2025) begin
            day_next   = 1;
            month_next = 1;
            year_next  = 2020;
          end else begin
            if (day == days_in_month) begin
              day_next = 1;
              if (month == 4'd12) begin
                month_next = 1;
                year_next  = year + 1;
              end else begin
                month_next = month + 1;
              end
            end else begin
              day_next = day + 1;
            end
          end
        end
        next_state = S_SEC;
      end
    endcase

    // Manually add minute
    if (add_minute) begin
      if (min == 6'd59) begin
        min_next = 0;
        if (AM_mode) begin
          if (hr == 6'd11) begin
            hr_next = 12;
            AM_PM_next = ~AM_PM;
          end else if (hr == 6'd12) begin
            hr_next = 1;
          end else begin
            hr_next = hr + 1;
          end
        end else begin
          if (hr == 6'd23)
            hr_next = 0;
          else
            hr_next = hr + 1;
        end
      end else begin
        min_next = min + 1;
      end
    end

    // Manually add hour
    if (add_hour) begin
      if (AM_mode) begin
        if (hr == 6'd11) begin
          hr_next = 12;
          AM_PM_next = ~AM_PM;
        end else if (hr == 6'd12) begin
          hr_next = 1;
        end else begin
          hr_next = hr + 1;
        end
      end else begin
        if (hr == 6'd23)
          hr_next = 0;
        else
          hr_next = hr + 1;
      end
    end
  end

endmodule


module timer_module(
    input clk,
    input reset,
    input set_timer,
    input  [3:0] timer_minutes,
    output reg timer_buzzer,
    output [5:0] timer_min_left,
    output [5:0] timer_sec_left
);
  reg [9:0] timer_sec_total;
  assign timer_min_left = timer_sec_total / 60;
  assign timer_sec_left = timer_sec_total % 60;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      timer_sec_total <= 0;
      timer_buzzer <= 0;
    end else begin
      if (set_timer && timer_sec_total == 0)
        timer_sec_total <= timer_minutes * 60;
      else if (timer_sec_total > 0) begin
        timer_sec_total <= timer_sec_total - 1;
        timer_buzzer <= (timer_sec_total == 1);
      end else
        timer_buzzer <= 0;
    end
  end
endmodule



module alarm_module(
    input clk,
    input reset,
    input set_alarm,
    input [5:0] alarm_hr,
    input [5:0] alarm_min,
    input [5:0] curr_hr,
    input [5:0] curr_min,
    input [5:0] curr_sec,
    output reg alarm_buzzer
);
  reg [5:0] alarm_hr_reg, alarm_min_reg;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      alarm_hr_reg  <= 0;
      alarm_min_reg <= 0;
      alarm_buzzer  <= 0;
    end else begin
      if (set_alarm) begin
        alarm_hr_reg  <= alarm_hr;
        alarm_min_reg <= alarm_min;
      end
      alarm_buzzer <= (curr_hr == alarm_hr_reg &&
                       curr_min == alarm_min_reg &&
                       curr_sec == 0);
    end
  end
endmodule


module digital_clock(
    input clk,
    input reset,
    input AM_mode,
    input set_timer,
    input [3:0] timer_minutes,
    input add_hour,
    input add_minute,
    input set_alarm,
    input [5:0] alarm_hr,
    input [5:0] alarm_min,
    output [5:0] sec,
    output [5:0] min,
    output [5:0] hr,
    output AM_PM,
    output [4:0] day,
    output [3:0] month,
    output [11:0] year,
    output timer_buzzer,
    output alarm_buzzer,
    output [5:0] timer_min_left,
    output [5:0] timer_sec_left
);
  timekeeper tk(clk, reset, AM_mode, add_hour, add_minute,
                sec, min, hr, AM_PM, day, month, year);

  timer_module tm(clk, reset, set_timer, timer_minutes,
                  timer_buzzer, timer_min_left, timer_sec_left);

  alarm_module am(clk, reset, set_alarm,
                  alarm_hr, alarm_min,
                  hr, min, sec,
                  alarm_buzzer);
endmodule



module the_clock(
    input        clk,
    input        reset,
    input        mode_btn,
    input        add_hour,
    input        add_minute,
    input        set_timer_btn,
    input        set_alarm_btn,
    input        AM_mode,
    output [5:0] sec,
    output [5:0] min,
    output [5:0] hr,
    output       AM_PM,
    output [4:0] day,
    output [3:0] month,
    output [11:0] year,
    output       timer_buzzer,
    output       alarm_buzzer,
    output [5:0] timer_min_left,
    output [5:0] timer_sec_left
);

  // FSM states
  localparam IDLE      = 2'd0,
             SET_TIMER = 2'd1,
             SET_ALARM = 2'd2;

  reg [1:0] state, next_state;

  // State register
  always @(posedge clk or posedge reset) begin
    if (reset) state <= IDLE;
    else       state <= next_state;
  end

  // Next-state logic
  always @(*) begin
    next_state = state;
    case(state)
      IDLE:      if (mode_btn) next_state = SET_TIMER;
      SET_TIMER: if (mode_btn) next_state = SET_ALARM;
      SET_ALARM: if (mode_btn) next_state = IDLE;
    endcase
  end
  wire idle_mode_active  = (state == IDLE);   
  wire timer_mode_active = (state == SET_TIMER);
  wire alarm_mode_active = (state == SET_ALARM);

  // Adjust timer_minutes in SET_TIMER
  reg [3:0] timer_minutes;
  always @(posedge clk or posedge reset) begin
    if (reset) timer_minutes <= 4'd0;
    else if (timer_mode_active && add_minute) timer_minutes <= timer_minutes + 1;
    else if (timer_mode_active && add_hour)   timer_minutes <= timer_minutes + 4;
  end

  // Adjust alarm_hr/min in SET_ALARM
  reg [5:0] alarm_hr, alarm_min;
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      alarm_hr  <= 6'd0;
      alarm_min <= 6'd0;
    end else if (alarm_mode_active && add_hour) begin
      alarm_hr <= (alarm_hr == (AM_mode ? 12 : 23)) ? 0 : alarm_hr + 1;
    end else if (alarm_mode_active && add_minute) begin
      alarm_min <= (alarm_min == 6'd59) ? 0 : alarm_min + 1;
    end
  end

  wire set_timer = timer_mode_active & set_timer_btn;
  wire set_alarm = alarm_mode_active & set_alarm_btn;
  wire time_add_hour=idle_mode_active?add_hour:1'b0;
  wire time_add_minute=idle_mode_active?add_minute:1'b0;
  digital_clock UDC (
    .clk(clk), .reset(reset), .AM_mode(AM_mode),
    .set_timer(set_timer),     .timer_minutes(timer_minutes),
    .add_hour(time_add_hour),           .add_minute(time_add_minute),
    .set_alarm(set_alarm),
    .alarm_hr(alarm_hr),       .alarm_min(alarm_min),
    .sec(sec), .min(min), .hr(hr), .AM_PM(AM_PM),
    .day(day), .month(month), .year(year),
    .timer_buzzer(timer_buzzer),
    .alarm_buzzer(alarm_buzzer),
    .timer_min_left(timer_min_left),
    .timer_sec_left(timer_sec_left)
  );

endmodule

