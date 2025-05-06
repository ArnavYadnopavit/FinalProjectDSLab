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

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sec <= 0;
            min <= 0;
            hr <= 12;
            AM_PM <= 0;
            day <= 1;
            month <= 1;
            year <= 2020;
        end else begin
            // Clock tick logic
            if (sec == 59) begin
                sec <= 0;

                if (min == 59) begin
                    min <= 0;

                    // Handle hour increment
                    if (AM_mode) begin
                        if (hr == 11) begin
                            hr <= 12;
                            AM_PM <= ~AM_PM;
                        end else if (hr == 12) begin
                            hr <= 1;
                        end else begin
                            hr <= hr + 1;
                        end
                    end else begin
                        if (hr == 23)
                            hr <= 0;
                        else
                            hr <= hr + 1;
                    end

                    // Date update logic
                    if ((AM_mode && hr == 12 && AM_PM == 0) || (!AM_mode && hr == 0)) begin
                        if (day == 31) begin
                            day <= 1;
                            if (month == 12) begin
                                month <= 1;
                                if (year == 2025)
                                    year <= 2020;
                                else
                                    year <= year + 1;
                            end else begin
                                month <= month + 1;
                            end
                        end else begin
                            day <= day + 1;
                        end
                    end

                end else begin
                    min <= min + 1;
                end

            end else begin
                sec <= sec + 1;
            end

            // Manual add_minute logic
            if (add_minute) begin
                if (min == 59) begin
                    min <= 0;

                    if (AM_mode) begin
                        if (hr == 11) begin
                            hr <= 12;
                            AM_PM <= ~AM_PM;
                        end else if (hr == 12) begin
                            hr <= 1;
                        end else begin
                            hr <= hr + 1;
                        end
                    end else begin
                        if (hr == 23)
                            hr <= 0;
                        else
                            hr <= hr + 1;
                    end

                end else begin
                    min <= min + 1;
                end
            end

            // Manual add_hour logic
            if (add_hour) begin
                if (AM_mode) begin
                    if (hr == 11) begin
                        hr <= 12;
                        AM_PM <= ~AM_PM;
                    end else if (hr == 12) begin
                        hr <= 1;
                    end else begin
                        hr <= hr + 1;
                    end
                end else begin
                    if (hr == 23)
                        hr <= 0;
                    else
                        hr <= hr + 1;
                end
            end
        end
    end

endmodule

module timer_module(
    input clk,
    input reset,
    input set_timer,
    input [3:0] timer_minutes,
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
                if (timer_sec_total == 1)
                    timer_buzzer <= 1;
                else
                    timer_buzzer <= 0;
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
            alarm_hr_reg <= 0;
            alarm_min_reg <= 0;
            alarm_buzzer <= 0;
        end else begin
            if (set_alarm) begin
                alarm_hr_reg <= alarm_hr;
                alarm_min_reg <= alarm_min;
            end
            if (curr_hr == alarm_hr_reg && curr_min == alarm_min_reg && curr_sec == 0)
                alarm_buzzer <= 1;
            else
                alarm_buzzer <= 0;
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

    timekeeper tk(
        .clk(clk), .reset(reset), .AM_mode(AM_mode),
        .add_hour(add_hour), .add_minute(add_minute),
        .sec(sec), .min(min), .hr(hr), .AM_PM(AM_PM),
        .day(day), .month(month), .year(year)
    );

    timer_module tm(
        .clk(clk), .reset(reset), .set_timer(set_timer),
        .timer_minutes(timer_minutes), .timer_buzzer(timer_buzzer),
        .timer_min_left(timer_min_left), .timer_sec_left(timer_sec_left)
    );


    alarm_module am(
        .clk(clk), .reset(reset), .set_alarm(set_alarm),
        .alarm_hr(alarm_hr), .alarm_min(alarm_min),
        .curr_hr(hr), .curr_min(min), .curr_sec(sec),
        .alarm_buzzer(alarm_buzzer)
    );

endmodule
