// traffic light controller solution stretch
// CSE140L 3-street, 20-state version, ew str/left decouple
// inserts all-red after each yellow
// uses enumerated variables for states and for red-yellow-green
// 5 after traffic, 10 max cycles for green when other traffic present
import light_package ::*;           // defines red, yellow, green

// same as Harris & Harris 4-state, but we have added two all-reds
module traffic_light_controller(
  input clk, reset, e_str_sensor, w_str_sensor, e_left_sensor, 
        w_left_sensor, ns_sensor,             // traffic sensors, east-west str, east-west left, north-south 
  output colors e_str_light, w_str_light, e_left_light, w_left_light, ns_light);     // traffic lights, east-west str, east-west left, north-south

  logic s, sb, e, eb, w, wb, l, lb, n, nb;	 // shorthand for traffic combinations:

  assign s  = e_str_sensor || w_str_sensor;					 // str E or W
  assign sb = e_left_sensor || w_left_sensor || ns_sensor;			     // 3 directions which conflict with s
  assign e  = e_left_sensor || e_str_sensor;					     // E str or L
  assign eb = w_left_sensor || w_str_sensor || ns_sensor;			 // conflicts with e
  assign w  = w_left_sensor || w_str_sensor;
  assign wb = e_left_sensor || e_str_sensor || ns_sensor;
  assign l  = e_left_sensor || w_left_sensor;
  assign lb = e_str_sensor || w_str_sensor || ns_sensor;
  assign n  = ns_sensor;
  assign nb = s || l; 

// 20 suggested states, 4 per direction   Y, Z = easy way to get 2-second yellows
// HRRRR = red-red following ZRRRR; ZRRRR = second yellow following YRRRR; 
// RRRRH = red-red following RRRRZ;
  typedef enum {GRRRR, YRRRR, ZRRRR, HRRRR, 	           // ES+WS
  	            RGRRR, RYRRR, RZRRR, RHRRR, 			   // EL+ES
	            RRGRR, RRYRR, RRZRR, RRHRR,				   // WL+WS
	            RRRGR, RRRYR, RRRZR, RRRHR, 			   // WL+EL
	            RRRRG, RRRRY, RRRRZ, RRRRH} tlc_states;    // NS
	tlc_states    present_state, next_state;
	integer ctr5, next_ctr5,       //  5 sec timeout when my traffic goes away
			ctr10, next_ctr10;     // 10 sec limit when other traffic presents

// sequential part of our state machine (register between C1 and C2 in Harris & Harris Moore machine diagram
// combinational part will reset or increment the counters and figure out the next_state
  always_ff @(posedge clk)
	if(reset) begin
	  present_state <= RRRRH;
	  ctr5          <= 0;
	  ctr10         <= 0;
	end  
	else begin
	  present_state <= next_state;
	  ctr5          <= next_ctr5;
	  ctr10         <= next_ctr10;
	end  

// combinational part of state machine ("C1" block in the Harris & Harris Moore machine diagram)
// default needed because only 6 of 8 possible states are defined/used
  always_comb begin
	next_state = RRRRH;                            // default to reset state
	next_ctr5  = 0; 							   // default: reset counters
	next_ctr10 = 0;
	case(present_state)
/* ************* Fill in the case statements ************** */
	  GRRRR: begin /* fill in the guts
			   build on part 1
			   round-robin priority for four other direcions
                */
		  if ( !s | ctr5 > 0) begin next_ctr5 = ctr5 + 1; //ctr keep going once u start 
            next_state = GRRRR;
          end
		  if ( sb | ctr10 > 0 ) begin next_ctr10 = ctr10 +1; //checking 4 sensor
            next_state = GRRRR;
          end
		  if (ctr5 ==  4 | ctr10 == 9 ) 
			  next_state = YRRRR; else next_state = GRRRR;
	         end

	YRRRR: next_state = ZRRRR;
	ZRRRR: next_state = HRRRR;
	HRRRR: begin
		if (e) next_state = RGRRR; //EL+ES
		else if (w) next_state = RRGRR; //WL+WS
		else if (l) next_state = RRRGR; // WL+EL
		else if (n) next_state = RRRRG; // NS
		else if (s) next_state = GRRRR; // ES+WS
	end
		
	  RGRRR: begin 		                                 // EL+ES green
		  if (!e | ctr5 > 0) begin next_ctr5 = ctr5 + 1;
			  next_state = RGRRR;
		  end
		  if (eb | ctr10 > 0 ) begin next_ctr10 = ctr10 +1;
			  next_state = RGRRR;
		  end
		  if (ctr5 == 4 | ctr10 == 9)
			  next_state = RYRRR; else next_state = RGRRR;
		   
	         end
		
	  RYRRR: next_state = RZRRR;
		
	  RZRRR: next_state = RHRRR;
		
	  RHRRR: begin
		  if (w) next_state = RRGRR; //WL+WS
		  else if (l) next_state = RRRGR; //WL+EL
		  else if (n) next_state = RRRRG; //NS
		  else if (s) next_state = GRRRR; //ES+WS
		  else if (e) next_state = RGRRR; //EL+ES
      end

	  RRGRR: //WL+WS
	         begin 
			 if ( !w | ctr5 > 0) begin next_ctr5 = ctr5 + 1; //ctr keep going once u start 
            next_state = RRGRR;
          end
			 if ( wb | ctr10 > 0 ) begin next_ctr10 = ctr10 +1; //checking 4 sensor
            next_state = RRGRR;
          end
		  if (ctr5 ==  4 | ctr10 == 9 ) 
			  next_state = RRYRR; else next_state = RRGRR;
	         end      
		  
      // ** fill in the guts to complete 5 sets of R Y Z H progressions. g reach end **

	RRYRR: next_state = RRZRR;
	RRZRR: next_state = RRHRR;
	RRHRR: begin
		if (l) next_state = RRRGR; //WL+EL
		else if (n) next_state = RRRRG; // NS
		else if (s) next_state = GRRRR; // ES+WS
		else if (e) next_state = RGRRR; // EL+ES
		else if (w) next_state = RRGRR; //WL+WS
      end

	RRRGR: // WL+EL, l
		 begin 
			 if ( !l | ctr5 > 0) begin next_ctr5 = ctr5 + 1; //ctr keep going once u start 
            next_state = RRRGR;
          end
			 if ( lb | ctr10 > 0 ) begin next_ctr10 = ctr10 +1; //checking 4 sensor
            next_state = RRRGR;
          end
		  if (ctr5 ==  4 | ctr10 == 9 ) 
			  next_state = RRRYR; else next_state = RRRGR;
	         end      

		RRRYR: next_state = RRRZR;
		RRRZR: next_state = RRRHR;
		RRRHR:  begin
			if (n) next_state = RRRRG; // NS
			else if (s) next_state = GRRRR; //ES+WS
			else if (e) next_state = RGRRR; //EL+ES
			else if (w) next_state = RRGRR; //WL+WS
			else if (l) next_state = RRRGR; //WL+EL
      end

	RRRRG:// NS, n
		 begin 
			 if ( !n| ctr5 > 0) begin next_ctr5 = ctr5 + 1; //ctr keep going once u start 
            next_state = RRRRG;
          end
			 if ( nb | ctr10 > 0 ) begin next_ctr10 = ctr10 +1; //checking 4 sensor
            next_state = RRRRG;
          end
		  if (ctr5 ==  4 | ctr10 == 9 ) 
			  next_state = RRRRY; else next_state = RRRRG;
	         end      
	RRRRY: next_state = RRRRZ;
	RRRRZ: next_state = RRRRH;
	RRRRH:  begin
		if (s) next_state = GRRRR; //ES+WS
		else if (e) next_state = RGRRR; //EL+ES
		else if (w) next_state = RRGRR; //WL+WS
		else if (l) next_state = RRRGR; //WL+EL
		else if (n) next_state = RRRRG; // NS
      end

	endcase
  end

// combination output driver  ("C2" block in the Harris & Harris Moore machine diagram)
	always_comb begin
	  e_str_light  = red;                // cover all red plus undefined cases
	  w_str_light  = red;				 // no need to list them below this block
	  e_left_light = red;
	  w_left_light = red;
	  ns_light     = red;
	  case(present_state)      // Moore machine
		GRRRR:   begin e_str_light = green;
					   w_str_light = green;
		end
      // ** fill in the guts for all 5 directions -- just the greens and yellows **
		YRRRR: begin
			  e_str_light = yellow;
					   w_str_light = yellow;
		  end

		ZRRRR: begin
			  e_str_light = yellow;
					   w_str_light = yellow;
		  end

		RGRRR: // EL+ES
			begin
			  	e_left_light = green;
		  		e_str_light = green;
			end

		RYRRR: begin
			e_left_light = yellow;
		  		e_str_light = yellow;
		end

		  RZRRR:  begin
			e_left_light = yellow;
		  		e_str_light = yellow;
		end

		  RRGRR: //WL+WS
			  begin
				  w_left_light = green;
				  w_str_light = green;
			  end

		  RRYRR: begin
			  w_left_light = yellow;
				  w_str_light = yellow;
		  end
		  
		  RRZRR: begin
			  w_left_light = yellow;
				  w_str_light = yellow;
		  end

		  RRRGR: //WL+EL
			  begin
				  w_left_light = green;
				  e_left_light = green;
			  end

		  RRRYR: begin 
			  w_left_light = yellow;
				  e_left_light = yellow;
			  end

		  RRRZR: begin 
			  w_left_light = yellow;
				  e_left_light = yellow;
			  end

		  RRRRG: // NS
			  ns_light = green;

		  RRRRY: ns_light = yellow;
		  RRRRZ: ns_light = yellow;

		  
	  endcase	  
	end

endmodule
