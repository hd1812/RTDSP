LIBRARY ieee;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.project_pack.ALL;

ENTITY rcb IS
	GENERIC(vsize : INTEGER := 6);
	PORT(
		clk          : IN  std_logic;
		reset        : IN  std_logic;

		-- db connections
		dbb		     : IN db_2_rcb;		
		dbb_delaycmd : OUT STD_LOGIC;
		dbb_rcbclear : OUT STD_LOGIC;

		-- vram connections
		vdout        : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		vdin         : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		vwrite       : OUT STD_LOGIC;
		vaddr        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

		-- vdp connection
		rcb_finish   : OUT STD_LOGIC
	);
END rcb;

ARCHITECTURE rtl1 OF rcb IS
--port match
		SIGNAL x            :  std_logic_vector(VSIZE-1 DOWNTO 0);
		SIGNAL y            :  std_logic_vector(VSIZE-1 DOWNTO 0);
		SIGNAL rcbcmd       :  std_logic_vector(2 DOWNTO 0);
		SIGNAL startcmd     :  std_logic;
--pix_word_cache
        SIGNAL pw, wen_all 				:  std_logic;
        SIGNAL pixnum           		:  std_logic_vector(3 DOWNTO 0);
        SIGNAL pixopin          		:  pixop_t;       
        SIGNAL opout,opram            	:	pixop_t;
  		SIGNAL rdout_par                :	store_t;
--ram_fsm
        SIGNAL start  					:	std_logic;
		SIGNAL delay					: 	std_logic;
		TYPE   state_t IS (m3, m2, m1, mx); --FSM states 
		SIGNAL state, nstate : state_t;
--split
		SIGNAL xin,yin 					:	 std_logic_vector(VSIZE-1 DOWNTO 0);
		SIGNAL word_num_new				:  	 std_logic_vector(7 DOWNTO 0);
--word_reg
		SIGNAL word_num_old				:  	 std_logic_vector(7 DOWNTO 0);
--equals
		SIGNAL same_word				:	 std_logic;	--check whether word number is same

--rcb_fsm
		TYPE   rstate_t IS (r2, r1,rx,rmv); --rcb_fsm states
		SIGNAL rstate,nrstate 			:		rstate_t;
		SIGNAL timer					:		std_logic_vector(4 DOWNTO 0);--terminate the process at the end of program
		SIGNAL cmd_slv					:		std_logic_vector(31 DOWNTO 0);--slv form of commands from pix_word_cache
		SIGNAL ram_in_slv				:		std_logic_vector(15 DOWNTO 0);--correct value of ram after drawing
		SIGNAL p1,p2					:		std_logic_vector(15 DOWNTO 0);--intermediate signal for generating correct value of ram
		SIGNAL delaycmd_i				:  		std_logic;--delay command request for clearing screen
--detect cmd is about draw or clear '1' means draw, '0' means clear
		SIGNAL move						:		std_logic;
		
--indicator
		SIGNAL cmd_same					:		std_logic;		
		SIGNAL cmd_reg					: 		std_logic_vector(1 DOWNTO 0);
		SIGNAL delaycmd					:   	std_logic;
BEGIN
	
--pix_word_cache design starts here, similar to previous exercises, but is_same signal is removed. For details please see CW4-------------------------------------------------------------------------------------------------------- 
change: PROCESS(pixopin,opram,pw,wen_all)
BEGIN
        opout<=pixopin;
        IF pixopin=pinvert OR pixopin = psame THEN
                IF wen_all='0' THEN
                        IF pixopin=psame THEN
                        opout<=opram;
                        ELSIF  opram=pblack THEN
                        opout<=pwhite;
                        ELSIF  opram=pwhite THEN
                        opout<=pblack;
                        ELSIF  opram=pinvert THEN
                        opout<=psame;
                        END IF;
                ELSIF pw='0' THEN
                        opout<=psame;
                END IF;
        END IF;
END PROCESS change;

--ram command generator of pix_word_cache
store_ram: PROCESS
BEGIN
        WAIT UNTIL clk'EVENT AND clk='1';
        IF reset='1'THEN
        rdout_par<=(OTHERS=>psame);
        ELSIF state=m3 or startcmd='0' THEN--If next cycle is m3 or startcmd is low, no need to write result.
        ELSIF wen_all='1'AND  pw='1' THEN
        rdout_par<=(OTHERS=>psame);
        rdout_par(to_integer(unsigned(pixnum)))<=opout;
        ELSIF wen_all='1'THEN
        rdout_par<=(OTHERS=>psame);
        ELSIF pw='1' THEN
        rdout_par(to_integer(unsigned(pixnum)))<=opout;
        END IF;
        IF same_word='0'THEN
        	rdout_par<=(OTHERS=>psame);
        END IF;
END PROCESS store_ram;
opram<=rdout_par(to_integer(unsigned(pixnum)));	--tracks the latest command cache

--pix_word_cache ends here--------------------------------------------------------------------------------------------------------------------------

--ram_fsm design. Same as exercises. Details explained in CW3--------------------------------------------------------------------------------------------------------
--The only difference is commented in the following
ram_fsm: PROCESS(state, start,same_word,timer)
	BEGIN
		nstate<=state;
		delay<='0';
		vwrite<='0';	
		CASE state IS
		WHEN mx=> 
			IF start='1' THEN 
				nstate<=m1; 
			END IF;
		WHEN m1=>
			nstate<=m2;--delay in m1 is no longer needed
		WHEN m2=>
			nstate<=m3;
			IF start='1' THEN 
				delay<='1'; 
			END IF;
			IF same_word='1'THEN
				nstate<=m2;
			END IF;
			IF timer="00100"THEN--output the final value before program terminates
				nstate<=m3;
			END IF;
		WHEN m3=>
			vwrite<='1'; 
			IF start='1' THEN 
				nstate<=m1; 
			ELSE
				nstate<=mx;
			END IF;		
		END CASE;
END PROCESS ram_fsm;

--Positively triggered process to change state and reset
clk_pos:	PROCESS
BEGIN
	WAIT UNTIL clk'EVENT and CLK='1';
	state<=nstate;
	IF reset='1' THEN
		state<=mx;
	END IF;
END PROCESS clk_pos;

--Negatively triggered process to pass address and data
clk_neg:	PROCESS
BEGIN
	WAIT UNTIL clk'EVENT and CLK='0';
	IF state/=m3 THEN
	vdin<=ram_in_slv;
	END IF;
	IF state=mx THEN--start new word reading
	vaddr<=word_num_new;
	END IF;
END PROCESS clk_neg;
cmd_slv<=store2slv(rdout_par);
--RAM_FAM ends here--------------------------------------------------------------------------------------------------------------------------

--This block splits x&y into pixel number and word number	
split: BLOCK
BEGIN
	word_num_new(3 DOWNTO 0)<=xin(5 DOWNTO 2);--First four digits are word number. (64 * 64 words in total)
	word_num_new(7 DOWNTO 4)<=yin(5 DOWNTO 2);
	pixnum(1 DOWNTO 0)<=xin(1 DOWNTO 0);--Last two digits are pixel number. (4*4 pixel in each word)
	pixnum(3 DOWNTO 2)<=yin(1 DOWNTO 0);
END BLOCK split;	

--This block stores the previous word number for comparison
word_reg: PROCESS
BEGIN
	WAIT UNTIL clk'EVENT and CLK='1';
	word_num_old<=word_num_new;
END PROCESS word_reg;	

--Following word_reg, this block checks whether word location changes, and set same_word to 0 if so.
equals: PROCESS(word_num_old,word_num_new,startcmd,cmd_same)
BEGIN
	same_word<='1';
	IF word_num_old /= word_num_new and startcmd='1' THEN 	--This is only valid when there is command coming in. This is necessary in our code design,
		same_word<='0'; 									-- since command coming from db block changes even when startcmd is low, which causes confusion of my rcb block.
	END IF;
	IF cmd_same='0' THEN
		same_word<='0';
	END IF;
END PROCESS equals;	

--This block stores the previous command for comparison
cmd_reg_i: PROCESS
BEGIN
	WAIT UNTIL CLK'EVENT and CLK='1';
	cmd_reg<=rcbcmd(1 DOWNTO 0);
END PROCESS cmd_reg_i;

--Following cmd_reg_i, this block assigns value to the indicator showing whether command changes.
cmd_same_i:PROCESS(rcbcmd,cmd_reg)
BEGIN
	cmd_same<='1';
	IF rcbcmd (1 DOWNTO 0)/=cmd_reg THEN
		cmd_same<='0';
	END IF;
END PROCESS cmd_same_i;

--Originally here is a multiplexer to choose coordinates(either from db or from clear screen block).
--In this version, clear_block is implemented in db_block, so MUX block is no longer needed.
xin<=x;
yin<=y;

--detect type of command. Either move or not. In the beginning this process is designed to check clear_screen command. Here this process is simplified
cmd_type:PROCESS
BEGIN
	WAIT UNTIL clk'EVENT and clk='1';
		move<='0';
		IF rcbcmd="000"THEN
			move<='1';
		END IF;
END PROCESS cmd_type;

--generate colour input for pix_word_cache, which detect colour of output from rcbcmd. Only the last two digits determines colour.
cnv: PROCESS(rcbcmd)
BEGIN
	IF rcbcmd(1)='1' THEN
		pixopin<=pblack;
		IF rcbcmd(0)='1'THEN
			pixopin<=pinvert;
		END IF;
	ELSE
		pixopin<=psame;
		IF rcbcmd(0) ='1'THEN
			pixopin<=pwhite;
		END IF;
	END IF;
END PROCESS cnv;

--FSM for rcb controller, which is similar to RAM_FSM but with extra outputs--------------------------------------------------------------------------------------------------------
rcb_fsm: Process(rstate,move,startcmd,same_word)
BEGIN
	nrstate<=rstate;
	delaycmd_i<='0';
	start<='0';
	wen_all<='0';
	pw<='1';
	CASE rstate IS
	WHEN rmv=>
		start<='1';
		nrstate<=r1;
		wen_all<='0';
		pw<='1';
	WHEN rx=>
		pw<='0';
		IF startcmd='1' THEN
			nrstate<=r1;
			start<='1';
			delaycmd_i<='1';
		END IF;
		IF move='1'and startcmd='1' THEN
			nrstate<=rmv;
		END IF;
	WHEN r1=>
		wen_all<='0';
		pw<='1';
		nrstate<=r2;
		delaycmd_i<='1';
		IF same_word ='1'THEN
			nrstate<=r1;
			delaycmd_i<='0';
		END IF;
	WHEN r2=>
		nrstate<=rx;
		delaycmd_i<='1';
	END CASE;
END PROCESS rcb_fsm;

--interface specifically designed for our db block. When system is busy and there is command coming in, set delaycmd to busy
Delay_Generation : PROCESS(startcmd, delaycmd_i, delay)
BEGIN
IF startcmd = '0' THEN 
  delaycmd <='0'; 
ELSE
  delaycmd<=delaycmd_i or delay;--split delaycmd to delaycmd_i (for potential clear_screen command) and delay (for RAM FSM)
END IF;
END PROCESS Delay_Generation;

rcb_clk_pos: PROCESS
BEGIN
	WAIT UNTIL clk'EVENT and CLK='1';
	rcb_finish<='0';
	rstate<=nrstate;
	IF reset='1' THEN
		rstate<=rx;
	END IF;
	IF timer="00000"THEN
		rcb_finish<='1';
	END IF;
	IF rstate=r2 THEN --reset timer to MAX if write executed. 
		timer<="11111";
	ELSIf timer/="00000" THEN
		timer<=std_logic_vector(unsigned(timer)-1);--timer will stop is write is not executed within 32 clock cycles.
	END IF;
END PROCESS rcb_clk_pos;
dbb_delaycmd<=delaycmd;
--RAM_FSM ENDS HERE----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--this process compare command with value stored in RAM to produce output value. The logics come from a true table about command, input pixel colour and output pixel colour.
reg3_pro: PROCESS(cmd_slv,vdout)
BEGIN
	FOR i in 0 to 15 LOOP
		p1(i)<=cmd_slv(2*i+1) and (not vdout(i)) ;
		p2(i)<=vdout(i) and (not cmd_slv(2*i)) ;
	END LOOP;
END PROCESS reg3_pro;
ram_in_slv<= p1 or p2;

--rcbclear function setting
dbb_rcbclear<='0';

--port matching
x<=dbb.x;
y<=dbb.y;
startcmd<=dbb.startcmd;
rcbcmd<=dbb.rcb_cmd;

END rtl1;      