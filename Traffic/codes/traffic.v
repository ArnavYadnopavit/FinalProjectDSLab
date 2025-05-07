module Traffic_Controller(
    input clk, rst, Emergency_left, Emergency_right,
    output reg T1_Red, T1_Green, T1_Yellow, T1_Orange, T1_Right,
    output reg T2_Red, T2_Green, T2_Yellow, T2_Orange, T2_Left,
    output reg T1_WALK, T2_WALK, Buzzer_Walk
);

    // State encoding
    parameter RED = 0;
    parameter YELLOW = 1;
    parameter GREEN = 2;
    parameter ORANGE = 3;
    parameter GREEN_WITH_TURN = 4;

    // Timing parameters
    parameter RED_TIME = 60;
    parameter GREEN_TIME = 20;
    parameter TURN_TIME = 10;
    parameter YELLOW_TIME = 5;
    parameter ORANGE_TIME = 10;
    parameter BUZZER_TIME = 5;
    parameter EMERGENCY_TIME = 10;

    // State variables
    reg [2:0] state_t1;
    reg [2:0] state_t2;
    reg [5:0] timer_t1;
    reg [5:0] timer_t2;
    reg emergency;
    reg [3:0] emergency_timer;

    // Emergency detection and timer
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            emergency <= 0;
            emergency_timer <= 0;
        end else begin
            if ((Emergency_left || Emergency_right) && !emergency) begin
                emergency <= 1;
                emergency_timer <= EMERGENCY_TIME;
            end else if (emergency && emergency_timer > 0) begin
                emergency_timer <= emergency_timer - 1;
                if (emergency_timer == 1) begin
                    emergency <= 0;
                end
            end
        end
    end

    // T1 State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_t1 <= RED;
            timer_t1 <= RED_TIME;
        end else if (!emergency) begin
            if (timer_t1 > 0) timer_t1 <= timer_t1 - 1;
            else begin
                case (state_t1)
                    RED: begin
                        state_t1 <= GREEN;
                        timer_t1 <= GREEN_TIME;
                    end
                    GREEN: begin
                        state_t1 <= GREEN_WITH_TURN;
                        timer_t1 <= TURN_TIME;
                    end
                    GREEN_WITH_TURN: begin
                        state_t1 <= ORANGE;
                        timer_t1 <= ORANGE_TIME;
                    end
                    ORANGE: begin
                        state_t1 <= YELLOW;
                        timer_t1 <= YELLOW_TIME;
                    end
                    YELLOW: begin
                        state_t1 <= RED;
                        timer_t1 <= RED_TIME;
                    end
                endcase
            end
        end
    end

    // T2 State Machine (synchronized to avoid conflicts)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_t2 <= GREEN_WITH_TURN;
            timer_t2 <= TURN_TIME;
        end else if (!emergency) begin
            if (timer_t2 > 0) timer_t2 <= timer_t2 - 1;
            else begin
                case (state_t2)
                    RED: begin
                        if (state_t1 != GREEN && state_t1 != GREEN_WITH_TURN) begin
                            state_t2 <= GREEN;
                            timer_t2 <= GREEN_TIME;
                        end
                    end
                    GREEN: begin
                        state_t2 <= GREEN_WITH_TURN;
                        timer_t2 <= TURN_TIME;
                    end
                    GREEN_WITH_TURN: begin
                        state_t2 <= ORANGE;
                        timer_t2 <= ORANGE_TIME;
                    end
                    ORANGE: begin
                        state_t2 <= YELLOW;
                        timer_t2 <= YELLOW_TIME;
                    end
                    YELLOW: begin
                        state_t2 <= RED;
                        timer_t2 <= RED_TIME;
                    end
                endcase
            end
        end
    end

always @(*) begin
    // Default all outputs off
    {T1_Red, T1_Green, T1_Yellow, T1_Orange, T1_Right} = 0;
    {T2_Red, T2_Green, T2_Yellow, T2_Orange, T2_Left} = 0;
    T1_WALK = 0;
    T2_WALK = 0;
    Buzzer_Walk = 0;

    if (emergency) begin
         T1_Red <= 1;
        if (Emergency_right)begin
             T2_Red <= 1;end
    end else begin
        // T1 signals
        case (state_t1)
            RED: T1_Red = 1;
            GREEN: T1_Green = 1;
            GREEN_WITH_TURN: begin T1_Green = 1; T1_Right = 1; end
            ORANGE: T1_Orange = 1;
            YELLOW: T1_Yellow = 1;
        endcase

        // T2 signals
        case (state_t2)
            RED: T2_Red = 1;
            GREEN: T2_Green = 1;
            GREEN_WITH_TURN: begin T2_Green = 1; T2_Left = 1; end
            ORANGE: T2_Orange = 1;
            YELLOW: T2_Yellow = 1;
        endcase

        // Walk and buzzer logic only active when not in emergency
        if (state_t1 == RED || state_t1 == YELLOW)
            T1_WALK = 1;
        if (state_t2 == RED || state_t2 == YELLOW)
            T2_WALK = 1;

        if (((state_t1 == RED || state_t1 == YELLOW) && timer_t1 <= BUZZER_TIME) ||
            ((state_t2 == RED || state_t2 == YELLOW) && timer_t2 <= BUZZER_TIME))
            Buzzer_Walk = 1;
    end
end

endmodule

