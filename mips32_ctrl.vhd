library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity mips32_ctrl is
    port(
        
        -- program flow
        inst_inp : in  std_logic_vector(31 downto 0);
        insten   : out std_logic;
        pgcen    : out std_logic;
        
        -- ALU control
        alu_func_sel_out : out std_logic_vector(2 downto 0);
        alu_l_sel_out    : out std_logic;
        alu_r_sel_out    : out std_logic;
        
        -- Register control signals
        den  : out std_logic;                                   -- d enable
        ten  : out std_logic;                                   -- t enable
        dsrc : out std_logic_vector(1 downto 0);                -- d src
        tsrc : out std_logic_vector(1 downto 0);                -- t source
        
        -- MDU control
        mdu_rdy_inp   : in  std_logic;
        mdu_start_out : out std_logic;
        
        -- Status signals
        cmp_eq_inp : in std_logic;
        cmp_gt_inp : in std_logic;
        
        -- comparator control
        cmp_r_sel_out: out std_logic;
        
        -- Controller data in
        ctrl_data_out : out std_logic_vector(31 downto 0);
        
        dbus_wren_out : out std_logic;
        
        clk     : in std_logic;
        resetn  : in std_logic);
end entity mips32_ctrl;

architecture behavior of mips32_ctrl is

    type op_type            is (no_op, add_op, addi_op, and_op, andi_op, beq_op, bgtz_op, divu_op, j_op, lui_op, lw_op, mfhi_op, mflo_op, mult_op, or_op, ori_op, sub_op, sw_op, syscall, xor_op, r_nop);
    type inst_state is (init,fetch,decode,execute,writeback);
    
    function getOp (op_code_tmp : std_logic_vector(5 downto 0); func_tmp : std_logic_vector(5 downto 0)) return op_type is
        VARIABLE return_val : op_type;
    begin
        case op_code_tmp is
            -- R instruction (mult,add,and,or,xor,sub,mfhi,mflo,divu)
            when "000000" =>
                case func_tmp is
                    when "001100" =>    return_val := syscall;   -- syscall
                    when "100000" =>    return_val :=  add_op;   -- add
                    when "100010" =>    return_val :=  sub_op;   -- sub
                    when "100100" =>    return_val :=  and_op;   -- and (bitwise)
                    when "100101" =>    return_val :=   or_op;   -- or (bitwise)
                    when "100110" =>    return_val :=  xor_op;   -- xor (bitwise)
                    when "011000" =>    return_val := mult_op;   -- mult
                    when "011011" =>    return_val := divu_op;   -- divu
                    when "010000" =>    return_val := mfhi_op;   -- mfhi
                    when "010010" =>    return_val := mflo_op;   -- mflo
                    -- other r instructions are not implemented
                    when others   =>    return_val :=    no_op;   --
                end case;
            -- J instruction
            when "000010" =>            return_val :=    j_op;   -- j
            -- BEQ 
            when "000100" =>            return_val :=  beq_op;   -- beq
            -- BGTZ
            when "000111" =>            return_val := bgtz_op;   -- bgtz
            -- I instructions (addi, andi, ori, lui)
            when "001000" =>            return_val := addi_op;   -- addi
            when "001100" =>            return_val := andi_op;   -- andi
            when "001101" =>            return_val :=  ori_op;   -- ori
            when "001111" =>            return_val :=  lui_op;   -- lui
            -- load instructions (sw, lw)
            when "100011" =>            return_val :=   lw_op;   -- lw
            when "101011" =>            return_val :=   sw_op;   -- sw
            -- Other instructions not implemented, count as NOP
            when others =>              return_val := no_op;     --
        end case;
        return return_val;
    end getOp;

    signal state     : inst_state := init;
    signal state_nxt : inst_state := init;    
    signal op_state  : op_type := no_op;
    
    -- field alias for instruction word
    alias optc  : std_logic_vector( 5 downto 0) is inst_inp(31 downto 26);
    alias func  : std_logic_vector( 5 downto 0) is inst_inp( 5 downto  0);    
    alias imval : std_logic_vector(25 downto 0) is inst_inp(25 downto  0);
    
begin
    ctrl : process(clk, resetn)
        variable state_next : inst_state := init;
        variable state_var  : inst_state := init;
    begin
        if resetn = '0' then
            --int0             <= '0';
            dbus_wren_out    <= '0';
            den              <= '0';
            ten              <= '0';
            dsrc             <= (others => '-');
            tsrc             <= (others => '-');
            pgcen            <= '0';
            insten           <= '0';
            alu_func_sel_out <= (others => '-');
            alu_l_sel_out    <= '-';
            alu_r_sel_out    <= '-';
            mdu_start_out    <= '0';
            cmp_r_sel_out    <= '-';
            ctrl_data_out    <= (others => '-');
            state            <= init;
            state_next       := init;
        elsif rising_edge(clk) then
            state       <= state_nxt;
            state_var   := state_nxt;
            case state_var is
                when init =>
                    --int0             <= '0';
                    insten           <= '0';
                    dbus_wren_out    <= '0';
                    den              <= '0';
                    ten              <= '0';
                    tsrc             <= (others => '-');
                    dsrc             <= (others => '-');
                    pgcen            <= '0';
                    alu_func_sel_out <= (others => '-');
                    alu_l_sel_out    <= '-';
                    alu_r_sel_out    <= '-';
                    mdu_start_out    <= '0';
                    cmp_r_sel_out    <= '-';
                    ctrl_data_out    <= (others => '-');
                    state_next       := fetch;
                when fetch =>
                    --int0             <= '0';
                    insten           <= '0';
                    dbus_wren_out    <= '0';
                    den              <= '0';
                    ten              <= '0';
                    tsrc             <= (others => '-');
                    dsrc             <= (others => '-');
                    pgcen            <= '0';
                    mdu_start_out    <= '0';
                    cmp_r_sel_out    <= '-';
                    alu_func_sel_out <= (others => '-');
                    alu_l_sel_out    <= '-';
                    alu_r_sel_out    <= '-';
                    ctrl_data_out    <= (others => '-');
                    state_next       := decode;
                when decode =>
                    --int0             <= '0';
                    insten           <= '0';
                    op_state         <= getOp(optc,func);    -- Update op state
                    case optc is
                        -- special instructions
                        when "000000" =>
                            case func is
                                -- add, sub, and, or, xor
                                when "100000"|"100010"|"100100"|"100101"|"100110" =>
                                    mdu_start_out <= '0';
                                    den           <= '1';
                                    dsrc          <= "00";
                                -- mult, divu
                                when "011000"|"011011"  =>
                                    mdu_start_out <= '1';
                                    -- Execute iterative algorithm;
                                    den           <= '0';
                                    dsrc          <= (others => '-');
                                -- mfhi
                                when "010000" =>
                                    mdu_start_out <= '0';
                                    den           <= '1';
                                    dsrc          <= "01";
                                -- mflo
                                when "010010" =>
                                    mdu_start_out <= '0';
                                    den           <= '1';
                                    dsrc          <= "10";
                                -- other special instructions are not implemented
                                when others => null;  
                                    mdu_start_out <= '0';
                                    den           <= '0';
                                    dsrc          <= (others => '-');
                            end case;
                            ten              <= '0';
                            tsrc             <= (others => '-');
                            pgcen            <= '0';
                            cmp_r_sel_out    <= '-';
                            if func(5 downto 3) = "100" then
                                alu_func_sel_out <= func(2 downto 0);
                            else
                                alu_func_sel_out <= (others => '-');
                            end if;
                              
                            -- s reg
                            alu_l_sel_out    <= '0';
                            -- t reg
                            alu_r_sel_out    <= '0';
                            ctrl_data_out    <= (others => '-');
                        -- J instruction
                        when "000010" =>
                            den              <= '0';
                            ten              <= '0';
                            tsrc             <= (others => '-');
                            dsrc             <= (others => '-');
                            pgcen            <= '1';
                            mdu_start_out    <= '0';
                            cmp_r_sel_out    <= '-';
                            -- nPGC := PGC & 0xFC000000
                            alu_func_sel_out <= "100";
                            alu_l_sel_out    <= '1';
                            alu_r_sel_out    <= '1';
                            ctrl_data_out    <= (31 downto 26 => '1') & (25 downto 0 => '0');
                        -- BEQ
                        when "000100" =>
                            den              <= '0';
                            ten              <= '0';
                            tsrc             <= (others => '-');
                            dsrc             <= (others => '-');
                            pgcen            <= '1';
                            mdu_start_out    <= '0';
                            -- t reg
                            cmp_r_sel_out    <= '1';
                            -- nPGC := PGC + 1
                            alu_func_sel_out <= "000";
                            alu_l_sel_out    <= '1';
                            alu_r_sel_out    <= '1';
                            ctrl_data_out    <= std_logic_vector(to_unsigned(1,32));
                        -- BGTZ
                        when "000111" =>
                            den              <= '0';
                            ten              <= '0';
                            tsrc             <= (others => '-');
                            dsrc             <= (others => '-');
                            pgcen            <= '1';
                            mdu_start_out    <= '0';
                            -- zero
                            cmp_r_sel_out    <= '0';
                            -- nPGC := PGC + 1
                            alu_func_sel_out <= "000";
                            alu_l_sel_out    <= '1';
                            alu_r_sel_out    <= '1';
                            ctrl_data_out    <= std_logic_vector(to_unsigned(1,32));
                        -- I instructions
                        when "001000" | "001100" | "001101" | "001111" =>
                            den              <= '0';
                            dsrc             <= (others => '-');
                            ten              <= '1';
                            if optc(2 downto 0) = "111" then
                                tsrc <= "01";
                            else
                                tsrc <= "00";
                            end if;
                            pgcen            <= '0';
                            mdu_start_out    <= '0';
                            cmp_r_sel_out    <= '-';
                            alu_func_sel_out <= optc(2 downto 0);
                            alu_l_sel_out    <= '0';
                            alu_r_sel_out    <= '1';
                            if optc(2 downto 0) = "000" then
                                ctrl_data_out <= (31 downto 16 => imval(15)) & imval(15 downto 0);
                            elsif optc(2 downto 0) = "111" then
                                ctrl_data_out <= imval(15 downto 0) & (15 downto 0 => '0');
                            else
                                ctrl_data_out <= (31 downto 16 => '0') & imval(15 downto 0);
                            end if;
                        -- LW
                        when "100011" =>
                            den              <= '0';
                            dsrc             <= (others => '-');
                            ten              <= '1';
                            tsrc             <= "10";
                            pgcen            <= '0';
                            mdu_start_out    <= '0';
                            cmp_r_sel_out    <= '-';
                            alu_func_sel_out <= "000";
                            -- eaddr := $s + offset
                            alu_l_sel_out    <= '0';
                            alu_r_sel_out    <= '1';
                            ctrl_data_out    <= (31 downto 16 => imval(15)) & imval(15 downto 0);
                        -- SW
                        when "101011" =>
                            den              <= '0';
                            dsrc             <= (others => '-');
                            ten              <= '0';
                            tsrc             <= (others => '-');
                            pgcen            <= '0';
                            mdu_start_out    <= '0';
                            cmp_r_sel_out    <= '-';
                            alu_func_sel_out <= "000";
                            -- eaddr := $s + offset
                            alu_l_sel_out    <= '0';
                            alu_r_sel_out    <= '1';
                            ctrl_data_out    <= (31 downto 16 => imval(15)) & imval(15 downto 0);
                        -- Other stuff not implemented
                        when others =>
                            den              <= '0';
                            dsrc             <= (others => '-');
                            ten              <= '0';
                            tsrc             <= (others => '-');
                            pgcen            <= '0';
                            mdu_start_out    <= '0';
                            cmp_r_sel_out    <= '-';
                            alu_func_sel_out <= (others => '-');
                            alu_l_sel_out    <= '-';
                            alu_r_sel_out    <= '-';
                            ctrl_data_out    <= (others => '-');
                    end case;
                    state_next           := execute;
                when execute =>
                    -- Now the instruction is actually executed
                    dbus_wren_out        <= '0';
                    ten                  <= '0';
                    tsrc                 <= (others => '-');
                    den                  <= '0';
                    dsrc                 <= (others => '-');
                    insten               <= '0';
                    mdu_start_out        <= '0';
                    cmp_r_sel_out        <= '-';
                    state_next           := writeback;
                    case optc is
                        -- Special
                        when "000000" =>
                            -- syscall
                            if func = "001100" then
                                --int0    <= '1';
                                pgcen            <= '1';
                                alu_func_sel_out <= "000";
                                alu_l_sel_out    <= '1';
                                alu_r_sel_out    <= '1';
                                ctrl_data_out    <= std_logic_vector(to_unsigned(1,32));
                            -- mult or divu
                            elsif func = "011000" or func = "011011" then
                               --int0 <= '0';
                               if mdu_rdy_inp = '0' then
                                    pgcen            <= '0';
                                    alu_func_sel_out <= (others => '-');
                                    alu_l_sel_out    <= '-';
                                    alu_r_sel_out    <= '-';
                                    ctrl_data_out    <= (others => '-');
                                    state_next       := execute;
                               else
                                    pgcen            <= '1';
                                    alu_func_sel_out <= "000";
                                    alu_l_sel_out    <= '1';
                                    alu_r_sel_out    <= '1';
                                    ctrl_data_out    <= std_logic_vector(to_unsigned(1,32));
                                end if;
                            else
                                --int0             <= '0';
                                --nPGC             := PGC + 1
                                pgcen              <= '1';
                                alu_func_sel_out   <= "000";
                                alu_l_sel_out      <= '1';
                                alu_r_sel_out      <= '1';
                                ctrl_data_out      <= std_logic_vector(to_unsigned(1,32));
                            end if;
                        -- J instruction
                        when "000010" =>
                            --int0             <= '0';
                            --nPGC             := PGC | imval
                            pgcen <= '1';
                            alu_func_sel_out <= "101";
                            alu_l_sel_out    <= '1';
                            alu_r_sel_out    <= '1';
                            ctrl_data_out    <= (31 downto 26 => '0') & imval;
                        -- BEQ instruction
                        when "000100" =>
                            --int0             <= '0';
                            pgcen            <= '1';
                            alu_func_sel_out <= "000";
                            alu_l_sel_out    <= '1';
                            alu_r_sel_out    <= '1';
                            if(cmp_eq_inp = '1') then
                                -- nPGC       := PGC + offset
                                ctrl_data_out <= (31 downto 16 => imval(15)) & imval(15 downto 0);
                            else
                                ctrl_data_out <= (others => '0');
                            end if;
                        -- BGTZ instruction
                        when "000111" =>
                            --int0             <= '0';
                            pgcen            <= '1';
                            alu_func_sel_out <= "000";
                            alu_l_sel_out    <= '1';
                            alu_r_sel_out    <= '1';
                            if(cmp_gt_inp = '1') then
                              -- nPGC         := PGC + offset
                                ctrl_data_out <= (31 downto 16 => imval(15)) & imval(15 downto 0);
                            else
                                ctrl_data_out <= (others => '0');
                            end if;
                        -- SW
                        when "101011" =>
                            dbus_wren_out    <= '1';
                        when others => 
                            --int0             <= '0';
                            --nPGC             := PGC + 1
                            pgcen            <= '1';
                            alu_func_sel_out <= "000";
                            alu_l_sel_out    <= '1';
                            alu_r_sel_out    <= '1';
                            ctrl_data_out    <= std_logic_vector(to_unsigned(1,32));
                    end case;
                when writeback =>
                    --int0             <= '0';
                    dbus_wren_out    <= '0';
                    den              <= '0';
                    ten              <= '0';
                    tsrc             <= (others => '-');
                    dsrc             <= (others => '-');
                    pgcen            <= '0';
                    insten           <= '1';
                    alu_func_sel_out <= (others => '-');
                    alu_l_sel_out    <= '-';
                    alu_r_sel_out    <= '-';
                    mdu_start_out    <= '0';
                    cmp_r_sel_out    <= '-';
                    ctrl_data_out    <= (others => '-');
                    state_next       := fetch;
                when others =>
                    -- do nothing
                    assert false report "Controller entered undefined state." severity error;
            end case;
            state_nxt <= state_next;
        end if;
    end process ctrl;
end architecture behavior;