.text 0x0000

// 中断向量区
	j	start					// reset
	add 	$zero, $zero, $zero			// 00000004
	add 	$zero, $zero, $zero			// 00000008
	add 	$zero, $zero, $zero			// 0000000C
	add 	$zero, $zero, $zero			// 00000010
	add 	$zero, $zero, $zero			// 00000014
	add 	$zero, $zero, $zero			// 00000018
	add 	$zero, $zero, $zero			// 0000001C
// 参数区
	add 	$zero, $zero, $zero			// 00000020	文本光标：0000XXYY
	add 	$zero, $zero, $zero			// 00000024	图形光标：00XXXYYY
	add 	$zero, $zero, $zero			// 00000028	键盘缓冲区头指针
	add 	$zero, $zero, $zero			// 0000002C	键盘缓冲区尾指针
	add 	$zero, $zero, $zero			// 00000030	键盘缓冲区低字： 最近4个ASCII码
	add 	$zero, $zero, $zero			// 00000034	键盘缓冲区第2字：次近4个ASCII码
	add 	$zero, $zero, $zero			// 00000038	键盘缓冲区第3字：次高4个ASCII码
	add 	$zero, $zero, $zero			// 0000003C	键盘缓冲区高字： 最高4个ASCII码
	add 	$zero, $zero, $zero			// 00000040	System Status Word:	shif=D31, press_hold=d30,
	add 	$zero, $zero, $zero			// 00000044	键盘扫描码缓冲区低：去掉F0
	add 	$zero, $zero, $zero			// 00000048	键盘扫描码缓冲区高：去掉F0
	add 	$zero, $zero, $zero			// 0000004C
	add 	$zero, $zero, $zero			// 00000050
	add 	$zero, $zero, $zero			// 00000054
	add 	$zero, $zero, $zero			// 00000058
	add 	$zero, $zero, $zero			// 0000005C
	add 	$zero, $zero, $zero			// 00000060
	add 	$zero, $zero, $zero			// 00000064
	add 	$zero, $zero, $zero			// 00000068
	add 	$zero, $zero, $zero			// 0000006C
	add 	$zero, $zero, $zero			// 00000070
	add 	$zero, $zero, $zero			// 00000074
	add 	$zero, $zero, $zero			// 00000078
	add 	$zero, $zero, $zero			// 0000007C

// 系统程序

start:					// 00000080
	addi	$sp, $zero, 0x4000		// 堆栈初始化，SP=4000
	sw	$zero, 0x20($zero)		// 初始化文本模式光标VRAM addre:	C0000+ROW*80+COL
	sw	$zero, 0x24($zero)		// 初始化图形模式光标

// 初始化接口
	addi	$s1, $zero, 0xff00		// $s1=FFFFFF00:	LED、SW、BTN读写端口
	add	$s2, $s1, $s1		// $s2=FFFFFE00：7段码显示端口
	addi	$s3, $zero, 0xd000		// $s3=ffffd000：PS2键盘端口

	addi	$s5, $zero, 0x7fff 		// 硬件计数器定时常数$s5=00007fff
	addi	$t1, $zero, 0x2AB		// $t1=000002AB=  1010101011
	sw 	$t1, 0x0($s1)			// 设置计数器通道counter_set=11控制端口和LED初始化值： {GPIOf0[21:	0], LED, counter_set}
	addi 	$t0, $zero, 0x2  		// XX M2 M1 M0 X
	sw 	$zero, 0x4($s1)		// 输出计数器控制字, 选择通道00
	lw 	$t1, 0x0($s1)			// 读进SW开关的状态:	{out0，out1，out2，D28-D20，LED7-LED7，BTN3-BTN0，SW7-SW0}
	add 	$t1, $t1, $t1		// 左移2位对齐SW输入与LED输出
	add 	$t1, $t1, $t1		// 保持计数通道0，对齐SW输入=LED输出
	sw 	$t1, 0x0($s1)  		// 设置计数器通道counter_set=00控制端口、LED=SW： {GPIOf0[21:	0], LED, counter_set}
	sw 	$s5, 0x4($s1) 		// counter ch0 :	ffffff04计数器地址，从00007fff开始减数计数，一直到00000000为止

// 初始化引导界面：
	lui		$t0, 0x000C
	addi  	$t0, $t0, 0x3F04
	addi  	$t5, $zero, 0x40

delay:
	lui 	$s4, 0xFFFC 			// 程序软件计数延时，时常数$s4=FFFF0000
//	addi	$s4, $zero, FFF
delay1:
	addi	$s4, $s4, 0x1			// 程序计数延时
	bne 	$s4, $zero, delay1	// 程序计数延时循环
	lw 	$t1, 0x0($s1)			// 读进SW开关的状态:	{out0，out1，out2，D28-D20，LED7-LED7，BTN3-BTN0，SW7-SW0}
	add 	$t1, $t1, $t1		//
	add 	$t1, $t1, $t1		// 左移2位对齐SW输入与LED输出
	sw 	$t1, 0x0($s1)  		// 设置计数器通道counter_set=00控制端口、LED=SW： {GPIOf0[21:	0], LED, counter_set}

	addi  $t9, $zero, 0x72E
	sw	$t9, 0x0($t0)
	addi  $t0, $t0, 0x4
	addi  $t5, $t5, -0x1
	bne   $t5, $zero, delay

//	jal	Clear_screen;

polling:
	jal	Cursor_out
	jal	Key_scan				// 扫描键盘
	beq	$v0, $zero, polling
	add	$s0, $zero, $v0
	add	$a0, $zero, $v0
	lui	$a1, 0x000C;
	addi	$a1, $a1, 0x1C
	addi	$a2, $zero, 0x700
	jal	disp_reg
	add	$a0, $zero, $s0
	jal	Key2ascii				// 转换ASCII
	addi	$a0, $v0, 0x700
	jal	disp_ascii				// 显示当前Ascii
	lw	$a0, 0x003C($zero)
	lui	$a1, 0x000C;
	addi	$a1, $a1, 0x15C
	addi	$a2, $zero, 0x600
	jal	disp_reg				// 显示最高ASCII高4位
	addi	$a1, $a1, 0x24
	lw	$a0, 0x0038($zero);
	jal	disp_reg				// 显示次高ASCII低4位
	addi	$a1, $a1, 0x24
	lw	$a0, 0x0034($zero);
	jal	disp_reg				// 显示次低ASCII低4位
	addi	$a1, $a1, 0x24
	lw	$a0, 0x0030($zero);
	jal	disp_reg				// 显示最低ASCII低4位

	add	$v0, $zero, $s0

	addi	$t3, $zero, 0x7000			// →：E074
	add	$t3, $t3, $t3
	addi	$t0, $t3, 0x74
	bne	$v0, $t0, Next_com1
	lw	$t1, 0x0020($zero)
	addi	$t1, $t1, 0x0000
	sw	$t1, 0x0020($zero);
Next_com1:
	addi	$t0, $t3, 0x6B				// ←：E06B
	bne	$v0, $t0, Next_com2
	lw	$t1, 0x0020($zero)
	addi	$t1, $t1, -0x0002
	sw	$t1, 0x0020($zero);
Next_com2:
	addi	$t0, $t3, 0x75				// ↑：E075
	bne	$v0, $t0, Next_com3
	lw	$t1, 0x0020($zero)
	addi	$t1, $t1, -0x0101
	sw	$t1, 0x0020($zero);
Next_com3:
	addi	$t0, $t3, 0x72				// ↓：E072
	bne	$v0, $t0, Next_com4
	lw	$t1, 0x0020($zero)
	addi	$t1, $t1, 0x0100
	addi	$t1, $t1, -0x0001
	sw	$t1, 0x0020($zero)
Next_com4:
	addi	$t0, $zero, 0x005A			// 左回车
	beq	$v0, $t0, CR_OK
	addi	$t0, $t3, 0x5A				// 右回车
	bne	$v0, $t0, polling
CR_OK:
	jal	LF

command:
	lw	$t1, 0x0030($zero)
	lw	$t2, 0x0034($zero)
	lui	$t0, 0x434C				// CL
	addi	$t0, $t0, 0x4552			// ER
	bne	$t1, $t0, Go_TEST
	jal	Clear_screen			// 清屏

Go_TEST:						// TEST
	lui	$t0, 0x5445				// TE
	addi	$t0, $t0, 0x5354			// ST
	bne	$t1, $t0, Go_DREG
	jal	Test

Go_DREG:						// 显示寄存器
	lui	$t0, 0x4452				// DR
	addi	$t0, $t0, 0x4547			// EG
	bne	$t1, $t0, Go_DMEM
	jal	Cursor_VRAM_Addr
	add	$a1, $zero, $v0
	jal	disp_reg_all;

Go_DMEM:						// 显示指定内存单元
	lui	$t0, 0x444D				// DMEM
	addi	$t0, $t0, 0x454D			// EM
	bne	$t1, $t0, GO_OTHE
	jal	Cursor_VRAM_Addr
	add	$a1, $zero, $v0
	jal	disp_mem_any;

GO_OTHE:
	sw	$zero, 0x0030($zero)
	sw	$zero, 0x0034($zero)
	sw	$zero, 0x0038($zero)
	sw	$zero, 0x003C($zero)
	j	polling

// ++++++++++++++++++++++++++++++++++应用程序
Test:
	lw 	$t1, 0x0($s1)				// 读进SW开关的状态:	{out0，out1，out2，D28-D20，LED7-LED7，BTN3-BTN0，SW7-SW0}
	add 	$t1, $t1, $t1			// 对齐SW输入与LED输出
	add 	$t1, $t1, $t1			// 保持计数通道0，对齐SW输入=LED输出
	sw 	$t1, 0x0($s1)  			// 设置计数器通道counter_set=00控制端口、LED=SW： {GPIOf0[21:	0], LED, counter_set}
	sw 	$s5, 0x4($s1) 			// counter ch0 :	ffffff04计数器地址，从0000ffff开始减数计数，一直到00000000为止
	lui 	$t9, 0xFFFF 				// 程序软件计数延时，时常数$t9=FFFF0000

	addi	$sp, $sp, -0x4
	sw	$ra, 0x0($sp)				// 保存返回主程序地址

loop2:
	jal	Key_scan
	addi	$t0, $zero, 0x15			//
	addi	$t1, $zero, 0x00FF
	and	$v0, $v0, $t1
	beq	$v0, $t0, Test_re
	beq	$v0, $zero, LLk

	add	$a0, $t8, $zero
	lui	$a1, 0x000C;
	addi	$a1, $a1, 0x20
	addi	$a2, $zero, 0x400
	jal	disp_reg				// VGA显示当前Key data值
	addi	$a1, $a1, 0x24
	addi	$a2, $zero, 0x600
	jal	disp_reg				// VGA显示当前键盘扫描码

	add	$a0, $zero, $v0
	jal	Key2ascii				// 转换ASCII
	addi	$a0, $v0, 0x700
	jal	disp_ascii				// 显示当前Ascii
	lw	$a0, 0x003C($zero)
	lui	$a1, 0x000C;
	addi	$a1, $a1, 0x15C
	addi	$a2, $zero, 0x600
	jal	disp_reg				// 显示最高ASCII高4位
	addi	$a1, $a1, 0x24
	lw	$a0, 0x0038($zero);
	jal	disp_reg				// 显示次高ASCII低4位
	addi	$a1, $a1, 0x24
	lw	$a0, 0x0034($zero);
	jal	disp_reg				// 显示次低ASCII低4位
	addi	$a1, $a1, 0x24
	lw	$a0, 0x0030($zero);
	jal	disp_reg				// 显示最低ASCII低4位
LLk:

	addi	$a0, $zero, 0x0000;
	lui	$a1, 0x000C;
	addi  $a1, $a1, 0x500
	jal	disp_mem

	addi	$a0, $zero, 0x3D00;
	lui	$a1, 0x000C;
	addi  $a1, $a1, 0x2580
	jal	disp_mem


	lw  	$t1, 0x0($s1)
	add 	$t1, $t1, $t1				// 对齐SW输入与LED输出
	add 	$t1, $t1, $t1			// 保持计数通道0，对齐SW输入=LED输出
	sw		$t1, 0x0($s1)				// 通过ffffff00输出SW状态到LED循环显示，即LED=SW： {GPIOf0[21:	0], LED, counter_set}

	lw  	$t1, 0x0($s1)
	lui	$t0, 0x8000
	and 	$t2, $t1, $t0
	addi	$t9, $t9, 0x1				// 程序计数延时
	beq 	$t2, $t0, C_init 			// Counter通道0溢出 修改7段码显示，并初始化计数器 C_init
//	beq 	$t9, $zero, C_init		// 程序计数延时结束，修改7段码显示。硬件或软件计数二选一
// ----------------------------------	// 判断7段码显示模式：SW[4:	3]控制
l_next:
	lw  	$t1, 0x0($s1);
	addi 	$t0, $zero, 0x18 			// $t0=00000018(00011000)
	and 	$11, $t1, $t0
	beq 	$11, $zero, L20 			// SW[4:	3]=00, 7段显示"点"循环移位：L20，SW0=0
	beq 	$11, $t0, L21 			// SW[4:	3]=11，显示七段图形，L21，SW0=0
	addi	$t0, $zero, 0x8			// $t0=8
	beq 	$11, $t0, L22 			// SW[4:	3]=01, 七段显示预置数字，L22，SW0=1
	sw 	$t8, 0x0($s2) 			// SW[4:	3]=10，显示$t8，SW0=1
	j 	loop2
// --------------------------------------- IO输出 --------

L20:
	nor	$t0, $zero, $zero;
	bne 	$s6, $t0, L3;
	nor 	$s6, $zero, $zero			// $s6=ffffffff全暗, 转移L4修改为fffffffe
	add 	$s6, $s6, $s6			// $s6=fffffffe
L3:
	sw 	$s6, 0x0($s2)				// SW[4:	3]=00, 7段显示点移位后显示
	j 	loop2

L21:
	lw 	$t8, 0x3B98($s7)
	sw 	$t8, 0x0($s2)				// SW[4:	3]=11，显示七段图形
	j 	loop2
L22:
	lw 	$t8, 0x3B58($s7)
	sw 	$t8, 0x0($s2)				// SW[4:	3]=01, 七段显示预置数字
	j 	loop2

Test_re:
	lw	$ra, 0x0($sp)				// 恢复返回主程序地址
	addi	$sp, $sp, 0x4
	jr	$ra

// ----------------------------------------计数结束，修改显示和计数重置------------------------------------------------
C_init:
	lui 	$t9, 0x3FFF 				// $t9=FFFF0000
	add 	$s6, $s6, $s6			// $s6=fffffffc，7段图形点左移
	addi  $t0, $zero, 0x1
	or 	$s6, $s6, $t0			// $s6末位置1，对应右上角不显示

	addi 	$s7, $s7, 0x4				// $s7=00000004，LED图形访存地址+4
	addi	$t0, $zero, 0x3f
	and 	$s7, $s7, $t0			// $s7=000000XX，屏蔽地址高位，只取6位

//	add	$t8, $t3, $zero			// 显示PS2值**********				add 	$t8, $t8, $2				// $t8+1 addi 	$t8, $t8, 1	// $t8+1
//	nor   $t0, $zero, $zero
//	beq 	$t8, $t0, l6				// 若$t8=ffffffff, 重置$t8=5
//	j 	l7
// l6:
//	addi $t8, $t8, 5 				// $t8=00000005

l7:
	lw		$t1, 0x0($s1)
	add 	$t2, $t1, $t1			// 对齐SW输入与LED输出
	add 	$t2, $t2, $t2			// 设计计数通道0，保持SW输入=LED输出
	sw		$t2, 0x0($s1)				// 设置计数通道0
	sw 		$s5, 0x4($s1)				// 计数器通道0初值

C_start:						// 如何用硬件解决记数死锁？
	lw		$t1, 0x0($s1)
	lui 	$t2, 0x8000
	and 	$t0, $t1, $t2
	beq 	$t0, $t2, C_start
	j 	l_next




// +++++++++++++++++++++++++++++++++++系统调用程序++++++++++++++++++++++++++++
// ----------------------------------------清屏
Clear_screen:
	addi	$sp, $sp, -0x0C
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)

	lui  	$t2, 0x000C
	addi 	$t0, $zero, 0x4B00 			// 显存VRAM单元数
CL_next:
	sw   	$zero, 0x0($t2)
	addi 	$t2, $t2, 0x4
	addi	$t0, $t0, -0x1
	bne  	$t0, $zero, CL_next
	addi 	$t0, $zero, 0x0001			// 置文本光标
	sw		$t0, 0x20($zero)
	addi	$t0, $zero, 0x72d			// "-"
	lui	$t2, 0x000C
	sw   	$t0, 0x0($t2)

	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x0C
	jr	$ra

// ---------------------------------------读PS2键盘扫描码

Key_scan:
	addi	$sp, $sp, -0x14
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)
	sw	$t8, 0x10($sp)

	add	$v0, $zero, $zero
	add	$t8, $zero, $zero
	lw	$t3, 0x0($s3)
	lui	$t0, 0x8000
	and	$t1, $t3, $t0
	bne	$t1, $t0, Key_ret			// 没有按键返回$v0=0

key_proceed:
	addi	$t0, $zero, 0x00FF
	and   $t3, $t3, $t0			// 屏蔽高位，得到当前Key Data
	and	$t2, $t8, $t0			// 保存按下时扫描码
	sll	$t8, $t8, 0x8				// 左移8位
	add	$t8, $t8, $t3			// 锁存当前Key Data在低8位，历史Key Data在高位
	sw	$t8, 0x0($s2)				// 送7段码显示
	addi	$t0, $zero, 0x0012			// left shift
	beq	$t0, $t3, Key_shift
	addi	$t0, $zero, 0x0059			// right shift
	bne	$t0, $t3, Key_E0F0
Key_shift:
	lw	$t0, 0x0040($zero)
	lui	$t1, 0x8000
	or	$t0, $t1, $t0
	sw	$t0, 0x0040($zero)			// 设置shift标志
Key_E0F0:
	addi	$t0, $zero, 0x7078			// E0F0
	add	$t0, $t0, $t0
	sll	$t1, $t8, 0x10
	srl	$t1, $t1, 0x10
	beq	$t0, $t1, Key_next_E0		// 若是扩展释放按键码，读经紧随的键盘扫描码，丢弃F0释放码
	addi	$t0, $zero, 0x00F0			// 判断按键释放码：F0
	beq	$t3, $t0, Key_next_F0		// 若是释放按键码，读经紧随的键盘扫描码，丢弃F0释放码

	lw	$t1, 0x0040($zero)			// 判断长按标志, 若长按, 继续读键盘扫描码
	lui	$t0, 0x4000
	and	$t1, $t1, $t0
	beq	$t1, $t0, scan2mem

	beq	$t3, $t2, Press_hold		// 非常按，判断长按, 若长按, 继续读键盘扫描码。Press_hold
	srl	$t2, $t8, 0x10				// 判断扩展键长按码：E0
	addi	$t0, $zero, 0x00FF			// 判断扩展键长按码：E0
	and	$t2, $t2, $t0
	addi	$t0, $zero, 0x00E0
	beq	$t0, $t2, Press_hold		// 若是扩展键长按码，保存E0, 准备读经紧随的键盘扫描码

Key_again:
	lw	$t3, 0x0($s3)
	lui	$t0, 0x8000
	and	$t1, $t3, $t0
	bne	$t1, $t0, Key_again		// 接收下一个按键扫描码
	j	key_proceed



Key_next_E0:
	addi	$t3, $zero, 0x00E0
Key_next_F0:
	lw	$t2, 0x0040($zero)			// 清除长按标志,
	lui	$t0, 0xBFFF
	and	$t2, $t2, $t0
	sw	$t2, 0x0040($zero);
	j	Key_next;

Press_hold:						// 若长按, 建立长按标志
	lw	$t2, 0x0040($zero)
	lui	$t0, 0x4000
	or	$t2, $t2, $t0
	sw	$t2, 0x0040($zero);

scan2mem:						// 扫描码放入缓冲区：00000044 00000048
	sll	$v0, $v0, 0x8				// 左移8位
	add	$v0, $v0, $t3			// 暂存当前键盘扫描码在低8位，历史扫描码在高位

	lw	$t0, 0x44($zero)
	srl	$t1, $t0, 0x18
	sll	$t0, $t0, 0x8
	add	$t0, $t0, $t3
	sw	$t0, 0x44($zero)
	lw	$t0, 0x48($zero)
	sll	$t0, $t0, 0x8
	add	$t0, $t0, $t1
	sw	$t0, 0x48($zero)
	addi	$t0, $zero, 0x00E0			// 判断扩展键扫描码：E0
	bne	$t3, $t0, Key_ret			// 若是扩展键长按码，读经紧随的键盘扫描码

Key_next:						// 读后续Key data
	lw	$t3, 0x0($s3)
	lui	$t0, 0x8000
	and	$t1, $t3, $t0
	bne	$t1, $t0, Key_next
	addi	$t0, $zero, 0x00FF
	and   $t3, $t3, $t0			// 屏蔽高位，得到当前Key Data
	addi	$t0, $zero, 0x00F0			// 判断按键释放码：F0
	beq	$t3, $t0, Key_next			// 若是释放按键码，读经紧随的键盘扫描码，丢弃F0释放码

	sll	$t8, $t8, 0x8				// 左移8位
	add	$t8, $t8, $t3			// 锁存当前Key Data在低8位，历史Key Data在高位
	sw	$t8, 0x0($s2)				// 送7段码显示
	addi	$t0, $zero, 0x7800
	add	$t0, $t0, $t0
	sll	$t2, $t8, 0x10
	srl	$t2, $t2, 0x10
	addi	$t0, $t0, 0x12
	beq	$t0, $t2, Key_shift_up
	addi	$t0, $t0, 0x47				// right shift
	bne	$t0, $t2, scan2mem
Key_shift_up:
	lw	$t0, 0x0040($zero)
	lui	$t1, 0x7FFF
	and	$t0, $t1, $t0
	sw	$t0, 0x0040($zero)			// 清shift标志
	j	scan2mem

// Key2:
//	addi	$t0, $zero, 7F80
//	add	$t0, $t0, $t0			// $t0=0000 FF 00
//	and	$t1, $t8, $t0			// $t1=0000 XX 00
//	addi	$t0, $zero, 7800
//	add	$t0, $t0, $t0			// $t0=0000 F0 00
//	beq   $t1, $t0, Key_ret			// 若前一Key data是释放码F0则返回主程序
//	srl	$t1, $t1, 8
//	beq   $t1, $t3, Key_ret			// 若前一Key data=当前键也返回主程序

Key_ret:

	lw	$t0, 0x00($sp)
	lw	$t1, 0x04($sp)
	lw	$t2, 0x08($sp)
	lw	$t3, 0x0C($sp)
	lw	$t8, 0x10($sp)
	addi	$sp, $sp, 0x14
	jr	$ra


// ---------------------------------------屏幕换行
LF:
	addi	$sp, $sp, -0x0C
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)

	lw	$t0, 0x20($zero)
	addi	$t1, $zero, 0x7F
	and	$t2, $t0, $t1			// 截取光标列
	addi	$t2, $zero, 0x0			// 列清零：置1
	nor	$t1, $t1, $t1
	and	$t0, $t1, $t0			// 截取光标行
	addi	$t0, $t0, 0x100			// 行+1
	addi	$t1, $zero, 0x3C00
	bne	$t0, $t1, LF_ret
	addi	$t0, $zero, 0x00			// 行清零
	addi	$sp, $sp, -0x04
	sw	$ra, 0x00($sp)
	jal	Clear_screen
	lw	$ra, 0x00($sp)
	addi	$sp, $sp, 0x04

LF_ret:
	add	$t0, $t0, $t2
	sw	$t0, 0x20($zero)

	addi	$sp, $sp, -0x04
	sw	$ra, 0x00($sp)
	addi	$a0, $zero, 0x72d			// "-"
	jal	disp_ascii
	lw	$ra, 0x00($sp)
	addi	$sp, $sp, 0x04

	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x0C
	jr	$ra

// ---------------------------------------显示当前寄存器值
disp_reg:
	addi	$sp, $sp, -0x14
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)
	sw	$t4, 0x10($sp)

	addi	$t4, $zero, 0x8
	addi	$t3, $a1, 0x1C				// 设置显示最低位地址

char_rp:
	addi	$t2, $zero, 0x0F			// 一位16进制转换成ASCII码
	and	$t0, $a0, $t2;
	addi	$t1, $zero, 0x9;
	slt	$t2, $t1, $t0
	addi	$t0, $t0, 0x30				// 小于A+30
	beq	$t2, $zero, cha$4_disp
	addi	$t0, $t0, 0x7				// 大于9则+7，16进制："A"=41=A+30+7

cha$4_disp:
	add	$t0, $t0, $a2			// 置显示颜色
	sw 	$t0, 0x0($t3) 			// 送显存VRAM
	srl	$a0, $a0, 0x4				// 右移4位
	addi	$t3, $t3, -0x4				// 修改显示地址
	addi	$t4, $t4, -0x1;
	bne	$t4, $zero, char_rp		// 判断8位16进制数是否显示完

	lw	$t4, 0x10($sp)
	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x14
	jr	$ra

// ---------------------------------------显示所有寄存器值
disp_reg_all:
	addi	$sp, $sp, -0x1C
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)
	sw	$t4, 0x10($sp)
	sw	$t5, 0x14($sp)
	sw	$ra, 0x18($sp)

	addi	$sp, $sp, -0x80
	sw	$0, 0x00($sp)
	sw	$1, 0x04($sp)
	sw	$2, 0x08($sp)
	sw	$3, 0x0C($sp)

	addi	$3, $zero, 0x1C
	lui	$1, 0x0001
	addi	$1, $1, 0x0004
	jal	I_mem_addr;
I_mem_addr:
	sw	$4, 0x10($sp)			// 被修改 modified
	lw	$2, 0x00($ra)			// 取指令, 偏移00
	add	$2, $2, $1
	sw	$2, 0x00($ra)			// 修改指令
	addi	$3, $3, -0x1
	bne	$3, $zero, I_mem_addr
	lui	$2, 0xafa4
	addi	$2, $2, 0x0010
	sw	$2, 0x00($ra)

	add	$t3, $a1, $zero;
	addi	$t0, $zero, 0x4
	addi	$t1, $zero, 0x8
	addi	$t2, $zero, 0x0			// i

disp_reg_all_next:
	bne	$t2, $zero, L_at;
	addi	$t4, $zero, 0x452			// Ascii(52)=R
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4
	addi	$t4, $zero, 0x430
	j	L_R
L_at:
	addi	$t4, $zero, 0x1
	bne	$t2, $t4, L_vi
	addi	$t4, $zero, 0x461			// Ascii(61)=a
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $zero, 0x474			// Ascii(74)=t
	j	L_R
L_vi:
	slti	$t4, $t2, 0x4
	beq	$t4, $zero, L_ai
	addi	$t4, $zero, 0x476			// Ascii(76)=v
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $t2, -0x2				// i
	addi	$t4, $t4, 0x430;
	j	L_R;
L_ai:
	slti	$t4, $t2, 0x8
	beq	$t4, $zero, L_ti
	addi	$t4, $zero, 0x461			// Ascii(61)=a
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $t2, -0x4				// i
	addi	$t4, $t4, 0x430;
	j	L_R;
L_ti:
	slti	$t4, $t2, 0x10
	beq	$t4, $zero, L_si
	addi	$t4, $zero, 0x474			// Ascii(74)=t
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $t2, -0x8				// i
	addi	$t4, $t4, 0x430;
	j	L_R
L_si:
	slti	$t4, $t2, 0x18
	beq	$t4, $zero, L_t89
	addi	$t4, $zero, 0x473			// Ascii(73)=s
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $t2, -0x10				// i
	addi	$t4, $t4, 0x430;
	j	L_R
L_t89:
	slti	$t4, $t2, 0x1A
	beq	$t4, $zero, L_ki
	addi	$t4, $zero, 0x474			// Ascii(74)=t
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $t2, -0x10				// i
	addi	$t4, $t4, 0x430
	j	L_R;
L_ki:
	slti	$t4, $t2, 0x1C
	beq	$t4, $zero, L_gp
	addi	$t4, $zero, 0x46B			// Ascii(6B)=k
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $t2, -0x1A				// i
	addi	$t4, $t4, 0x430
	j	L_R
L_gp:
	addi	$t4, $zero, 0x1C
	bne	$t2, $t4, L_sp
	addi	$t4, $zero, 0x467			// Ascii(67)=g
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $zero, 0x470			// Ascii(70)=p
	j	L_R
L_sp:
	addi	$t4, $zero, 0x1D
	bne	$t2, $t4, L_fp
	addi	$t4, $zero, 0x473			// Ascii(73)=s
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $zero, 0x470			// Ascii(70)=p
	j	L_R
L_fp:
	addi	$t4, $zero, 0x1E
	bne	$t2, $t4, L_ra
	addi	$t4, $zero, 0x466			// Ascii(66)=f
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $zero, 0x470			// Ascii(70)=p
	j	L_R
L_ra:
	addi	$t4, $zero, 0x472			// Ascii(72)=r
	sw	$t4, 0x0($a1)
	addi	$a1, $a1, 0x4;
	addi	$t4, $zero, 0x461			// Ascii(61)=a
L_R:
	sw	$t4, 0x0($a1)				// i
	addi	$a1, $a1, 0x4;


	jal	reg_stack_addr;
reg_stack_addr:
	lw	$a0, 0x00($sp)
	add	$t5, $zero, $ra
	addi	$a2, $zero, 0x700
	jal	disp_reg
	add	$ra, $zero, $t5
	addi	$a1, $a1, 0x20
//	sw	$zero, 0($a1)
//	addi	$a1, $a1, 4
	lw	$2, 0x00($t5)			// 取指令, 偏移00
	addi	$2, $2, 0x4
	sw	$2, 0x00($t5)			// 修改指令
	addi	$t2, $t2, 0x1
	addi	$t1, $t1, -0x1
	bne	$t1, $zero, disp_reg_all_next
	addi	$t1, $zero, 0x8
	addi	$t3, $t3, 0x140
	add	$a1, $t3, $zero;
	addi	$t0, $t0, -0x1
	bne	$t0, $zero, disp_reg_all_next

	lui	$2, 0x8fa4
//	addi	$2, $2, 0010
	sw	$2, 0x00($t5)

	lw	$0, 0x00($sp)
	lw	$1, 0x04($sp)
	lw	$2, 0x08($sp)
	lw	$3, 0x0C($sp)
	addi	$sp, $sp, 0x80


	lw	$ra, 0x18($sp)
	lw	$t5, 0x14($sp)
	lw	$t4, 0x10($sp)
	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x1C
	jr	$ra


// ----------------------------------------// 内存显示
disp_mem:
	addi	$sp, $sp, -0x18
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)
	sw	$t4, 0x10($sp)
	sw	$ra, 0x14($sp)

	add	$t2, $a0, $zero			// 内存地址
	add	$t3, $a1, $zero			// 屏幕地址
	add	$a1, $t3, $zero
	addi	$t0, $zero, 0x18
	addi	$t1, $zero, 0x8
	addi	$a2, $zero, 0x600

	jal	disp_reg

	addi	$a1, $a1, 0x20
	sw	$zero, 0x0($a1)
	addi	$a1, $a1, 0x4

disp_mem_rp:
	lw	$a0, 0x0($t2)
	addi	$a2, $zero, 0x700
	jal	disp_reg;
	addi	$t2, $t2, 0x4
	addi	$a1, $a1, 0x20
	sw	$zero, 0x0($a1)
	addi	$a1, $a1, 0x4

	lui	$t4, 0xFFFF
	nor	$t4, $t4, $t4
	and	$t4, $t4, $a1
	slti	$t4, $t4, 0x4B00
	beq	$t4, $zero, Not_move
	jal	screen_move_up
	lui	$a1, 0x000C
	addi	$a1, $a1, 0x49C0

Not_move:
	addi	$t1, $t1, -0x1
	bne	$t1, $zero, disp_mem_rp
	addi	$t3, $t3, 0x140
	add	$a0, $zero, $t2
	add	$a1, $t3, $zero
	addi	$a2, $zero, 0x600;
	jal	disp_reg

	addi	$a1, $a1, 0x20
	sw	$zero, 0x0($a1)
	addi	$a1, $a1, 0x4
	addi	$t1, $zero, 0x8
	addi	$t0, $t0, -0x1
	bne	$t0, $zero, disp_mem_rp

	lw	$ra, 0x14($sp)
	lw	$t4, 0x10($sp)
	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x18
	jr	$ra

// ----------------------------------------// 指定地址内存显示
disp_mem_any:
	addi	$sp, $sp, -0x18
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)
	sw	$t4, 0x10($sp)
	sw	$ra, 0x14($sp)


	addi	$t0, $zero, 0x0038
	add	$t3, $zero, $zero
	addi	$t4, $zero, 0x2
mem_next_addr:
	lw	$t1, 0x0000($t0)
	srl	$a0, $t1, 0x18
	jal	ascii2Hex				// 3
	addi	$t2, $zero, 0x000F
	and	$v0, $v0, $t2
	sll	$t3, $t3, 0x4
	add	$t3, $t3, $v0
	sll	$a0, $t1, 0x8;
	srl	$a0, $a0, 0x18
	jal	ascii2Hex				// 2
	addi	$t2, $zero, 0x000F
	and	$v0, $v0, $t2
	sll	$t3, $t3, 0x4
	add	$t3, $t3, $v0
	sll	$a0, $t1, 0x10;
	srl	$a0, $a0, 0x18
	jal	ascii2Hex				// 1
	addi	$t2, $zero, 0x000F
	and	$v0, $v0, $t2
	sll	$t3, $t3, 0x4
	add	$t3, $t3, $v0
	sll	$a0, $t1, 0x18;
	srl	$a0, $a0, 0x18
	jal	ascii2Hex				// 0
	addi	$t2, $zero, 0x000F
	and	$v0, $v0, $t2
	sll	$t3, $t3, 0x4
	add	$t3, $t3, $v0
	addi	$t0, $t0, -0x4
	addi	$t4, $t4, -0x1
	bne	$t4, $zero, mem_next_addr


	add	$a0, $zero, $t3
//	lui	$a1, 000C
//	addi  $a1, $a1, 500
	jal	disp_mem

disp_mem_any_ret:
	lw	$ra, 0x14($sp)
	lw	$t4, 0x10($sp)
	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x18
	jr	$ra

// ----------------------------------------// 输出当前光标
Cursor_out:
	addi	$sp, $sp, -0x10
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)

	lw	$t2, 0x20($zero)			// 取当前光标
	addi	$t0, $zero, 0x7F
	and	$t3, $t2, $t0			// 取光标列
	add	$t3, $t3, $t3;
	addi	$t0, $zero, 0x3F00
	and	$t2, $t2, $t0			// 取光标行
	add	$t2, $t2, $t3			// 合成光标行列

	sll	$t2, $t2, 0x9			// 合计左移1+9位，对准GPIOf0[12:	0]位置, GPIO[12:	7]:	光标行，GPIO[6:	0]：光标列



	lw 	$t1, 0x0($s1)			// 读进SW开关的状态:	{out0，out1，out2，D28-D20，LED7-LED7，BTN3-BTN0，SW7-SW0}
	addi	$t0, $zero, 0x3FF
	and	$t1, $t1, $t0
	add 	$t1, $t1, $t1		//
	add 	$t1, $t1, $t1		// 左移2位SW输入对齐LED输出

	or	$t1, $t1, $t2		// 光标与其他FFFFFF00端口输出数据合并
	sw 	$t1, 0x0($s1)  		// 设置计数器通道counter_set=00控制端口、LED=SW和光标： {GPIOf0[21:	0], LED, counter_set}

	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x10
	jr	$ra

// ----------------------------------------// 计算当前光标VRAM地址
Cursor_VRAM_Addr:
	addi	$sp, $sp, -0x10
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)

	lw	$t2, 0x20($zero)			// 取当前光标
	addi	$t0, $zero, 0x7F
	and	$t3, $t2, $t0			// 取光标列
	addi	$t0, $zero, 0x3F00
	and	$t2, $t2, $t0			// 取光标行
	sll	$t0, $t2, 0x4				// 行乘80=50H
	sll	$t2, $t2, 0x6
	add	$t2, $t2, $t0
	add	$t2, $t2, $t3			// 行列合成光标扫描
	sll	$v1, $t2, 0x2				// 乘4，相对地址
	lui	$t0, 0x000C
	add	$v0, $v1, $t0			// 当前光标VRAM绝对地址

	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x10
	jr	$ra

// ----------------------------------------// 整屏上移一行
screen_move_up:
	addi	$sp, $sp, -0x10
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)

	addi	$t2, $t2, 0x1270
Next_move_up:
	lui	$t0, 0x000C;
	lw	$t1, 0x50($t0)
	sw	$t1, 0x00($t0)
	addi	$t0, $t0, 0x4
	addi	$t2, $t2, -0x1
	bne	$t2, $zero, Next_move_up
	addi	$t2, $t2, 0x50
clr_last_line:
	sw	$zero, 0x00($t0)
	addi	$t0, $t0, 0x4
	addi	$t2, $t2, -0x1
	bne	$t2, $zero, clr_last_line

	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x10
	jr	$ra

// ----------------------------------------// 扫描码转换ASCII
Key2ascii:
	addi	$sp, $sp, -0x10
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)

	addi	$t0, $zero, 0x7000
	add	$t0, $t0, $t0			// $t0=E000
	and	$t1, $a0, $t0
	bne	$t1, $t0, get_ascii
	lui	$t1, 0xFFFF
	nor	$t1, $t1, $t1
	and	$t1, $t1, $a0			// 获取扩展扫描码E0XX
	addi	$t2, $t0, 0x75				// ↑
	bne	$t2, $t1, Next_E01
	addi	$v0, $zero, 0x1E
	j	ascii_ret
Next_E01:
	addi	$t2, $t0, 0x72				// ↓
	bne	$t2, $t1, Next_E02
	addi	$v0, $zero, 0x1F
	j	ascii_ret
Next_E02:
	addi	$t2, $t0, 0x6B				// ←
	bne	$t2, $t1, Next_E03
	addi	$v0, $zero, 0x1D
	j	ascii_ret
Next_E03:
	addi	$t2, $t0, 0x74				// →
	bne	$t2, $t1, Next_E04
	addi	$v0, $zero, 0x1C
	j	ascii_ret
Next_E04:
	addi	$t2, $t0, 0x6C				// home
	bne	$t2, $t1, Next_E05
	addi	$v0, $zero, 0x0B
	j	ascii_ret
Next_E05:
	addi	$t2, $t0, 0x5A				// 小键盘回车
	bne	$t2, $t1, Next_E06
	addi	$v0, $zero, 0x0D
	j	ascii_ret
Next_E06:
	add	$zero, $zero, $zero
get_ascii:
	addi	$t0, $zero, 0x00FC
	and	$t1, $t0, $a0
	lw	$t1, 0x3C00($t1)			// 获得相邻4个Ascii
	addi	$t0, $zero, 0x03
	and	$t2, $t0, $a0
ascii_move:
	beq	$t2, $t0, ascii_re
ascii_move_next:					// 获得当前的Ascii, $t1=Ascii code
	srl	$t1, $t1, 0x8
	addi	$t0, $t0, -0x1
	bne	$t2, $t0, ascii_move_next
ascii_re:
	addi	$t0, $zero, 0x00FF
	and	$v0, $t0, $t1

	lw	$t0, 0x0040($zero)
	lui	$t1, 0x8000
	and	$t0, $t1, $t0
	bne	$t0, $t1, ascii2mem
// shif_12_59:
	addi	$v0, $v0, 0x20				// shif +20

//	lui	$t0, 00FF
//	and	$t2, $t0, $a0
//	lui	$t0, 0012
//	beq	$t2, $t0, shif_12_59
//	lui	$t0, 0059
//	bne	$t2, $t0, ascii2mem


ascii2mem:
	addi	$t0, $zero, 0x0D
	beq	$t0, $v0, ascii_ret

	lw	$t0, 0x30($zero)			// 0W
	srl	$t1, $t0, 0x18
	sll	$t0, $t0, 0x8
	add	$t0, $t0, $v0
	sw	$t0, 0x30($zero);

	lw	$t0, 0x34($zero)			// 1W
	srl	$t2, $t0, 0x18
	sll	$t0, $t0, 0x8
	add	$t0, $t0, $t1
	sw	$t0, 0x34($zero)

	lw	$t0, 0x38($zero)			// 2W
	srl	$t1, $t0, 0x18
	sll	$t0, $t0, 0x8
	add	$t0, $t0, $t2
	sw	$t0, 0x38($zero)

	lw	$t0, 0x3C($zero)			// 3W
//	srl	$t1, $t0, 18
	sll	$t0, $t0, 0x8
	add	$t0, $t0, $t1
	sw	$t0, 0x3C($zero);

ascii_ret:
	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x10
	jr	$ra

// ----------------------------------------// ASCII转换HEX
ascii2Hex:
	addi	$sp, $sp, -0x14
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)
	sw	$t3, 0x0C($sp)
	sw	$ra, 0x10($sp)

	add	$t2, $zero, $a0
	jal	Ascii029
	lui	$t0, 0x8000
	and	$t1, $v0, $t0
	beq	$t0, $t1, ascii2Hex_ret
	add	$a0, $zero, $t2
	jal	Asciia2f

ascii2Hex_ret:
	lw	$ra, 0x10($sp)
	lw	$t3, 0x0C($sp)
	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x14
	jr	$ra

// ----------------------------------------// 判断ASCii 0-9	并转换成16进制
Ascii029:
	addi	$sp, $sp, -0x0C
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)

	addi	$v0, $a0, -0x30
	addi	$t0, $zero, 0x0039 				// '9'
	slt	$t1, $t0, $a0				// ascii(39)<$a0, $t1=1
	bne	$t1, $zero, Ascii029_ret		// ascii(39)<$a0, 返回,
	addi	$t0, $zero, 0x0030 			// '0'
	slt	$t1, $a0, $t0				// $a0<ascii(30), $t1=1
	bne	$t1, $zero, Ascii029_ret		// $a0<ascii(30), 返回
	lui	$t0, 0x8000
	or	$v0, $v0, $t0				// ascii(30)<$a0<ascii(39), $v0=800000HEX

Ascii029_ret:
	lw	$t0, 0x00($sp)
	lw	$t1, 0x04($sp)
	lw	$t2, 0x08($sp)
	addi	$sp, $sp, 0x0C
	jr 	$ra

// ----------------------------------------// 判断ASCii a-f	并转换成16进制
Asciia2f:
	addi	$sp, $sp, -0x0C
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)

	addi	$v0, $a0, -0x37
	addi	$t0, $zero, 0x0046 			// 'F'
	slt	$t1, $t0, $a0				// ascii(46)<$a0, $t1=1
	bne	$t1, $zero, Asciia2f_ret		// ascii(46)<$a0, 返回,
	addi	$t0, $zero, 0x0041 			// 'A'
	slt	$t1, $a0, $t0				// $a0<ascii(41), $t1=1
	bne	$t1, $zero, Asciia2f_ret		// $a0<ascii(41), 返回
	lui	$t0, 0x8000
	or	$v0, $v0, $t0				// ascii(41)<$a0<ascii(46), $v0=800000HEX

Asciia2f_ret:
	lw	$t0, 0x00($sp)
	lw	$t1, 0x04($sp)
	lw	$t2, 0x08($sp)
	addi	$sp, $sp, 0x0C
	jr 	$ra


// ----------------------------------------// 当前光标位置显示ASCII
disp_ascii:
	addi	$sp, $sp, -0x0C
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)

	lw	$t0, 0x20($zero)
	addi	$t1, $zero, 0x3F00
	and	$t1, $t0, $t1			// 截取光标行
	srl	$t2, $t1, 0x1				// 行×80×4
	srl	$t2, $t2, 0x1
	add	$t2, $t2, $t1
	addi	$t1, $zero, 0x7F
	and	$t1, $t0, $t1			// 截取光标列
	add	$t1, $t1, $t1			// 列×4
	add	$t1, $t1, $t1
	add	$t2, $t2, $t1
	lui	$t1, 0x000C
	add	$t2, $t1, $t2
	add	$t1, $zero, $a0
	sw	$t1, 0x0($t2)

	addi	$sp, $sp, -0x04
	sw	$ra, 0x00($sp)
	jal	Cursor_move_F
	lw	$ra, 0x00($sp)
	addi	$sp, $sp, 0x04

//	addi	$t0, $t0, 1
//	sw	$t0, 20($zero)

	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x0C
	jr	$ra

// ----------------------------------------// 移动光标位置
Cursor_move_F:
	addi	$sp, $sp, -0x0C
	sw	$t0, 0x00($sp)
	sw	$t1, 0x04($sp)
	sw	$t2, 0x08($sp)

	lw	$t0, 0x20($zero)
	addi	$t1, $zero, 0x7F
	and	$t2, $t0, $t1			// 截取光标列
	addi	$t2, $t2, 0x1				// 列+1
	nor	$t1, $t1, $t1
	and	$t0, $t1, $t0			// 截取光标行
	addi	$t1, $zero, 0x50
	bne	$t2, $t1, Cursor_move_F_ret
	add	$t2, $zero, $zero			// 列清零
//	addi	$t1, $zero, 3F00
//	and	$t0, $t0, $t1			// 截取光标行
	addi	$t0, $t0, 0x100			// 行+1
	addi	$t1, $zero, 0x3C00
	bne	$t0, $t1, Cursor_move_F_ret
	addi	$t0, $zero, 0x00			// 行清零

	addi	$sp, $sp, -0x04
	sw	$ra, 0x00($sp)
	jal	Clear_screen
	lw	$ra, 0x00($sp)
	addi	$sp, $sp, 0x04

Cursor_move_F_ret:
	add	$t0, $t0, $t2
	sw	$t0, 0x20($zero)

	lw	$t2, 0x08($sp)
	lw	$t1, 0x04($sp)
	lw	$t0, 0x00($sp)
	addi	$sp, $sp, 0x0C
	jr	$ra

// ----------------------------------------// 寄存器保护
Save_reg:
	addi	$sp, $sp, -0x24
	sw	$s0, 0x00($sp)
	sw	$s1, 0x04($sp)
	sw	$s2, 0x08($sp)
	sw	$s3, 0x0C($sp)
	sw	$s4, 0x10($sp)
	sw	$s5, 0x14($sp)
	sw	$s6, 0x18($sp)
	sw	$s7, 0x1C($sp)
	sw	$ra, 0x20($sp)
	jr	$ra

// ----------------------------------------// 寄存器恢复
Restore_reg:
	lw	$s0, 0x00($sp)
	lw	$s1, 0x04($sp)
	lw	$s2, 0x08($sp)
	lw	$s3, 0x0C($sp)
	lw	$s4, 0x10($sp)
	lw	$s5, 0x14($sp)
	lw	$s6, 0x18($sp)
	lw	$s7, 0x1C($sp)
	lw	$ra, 0x20($sp)
	addi	$sp, $sp, 0x24
	jr	$ra


// ---------------------------------------数据区
Data_area:
	jr	$ra
// WELCOME TO Truths!:	57454C43 4F4D4520 544F2054 72757468 73210000
// Practice Platform of Computer System Hardware&Software:
// 50726163 74696365 20506C61 74666F72 6D206F66 20436F6D 70757465 72205379 7374656D 20486172 64776172 6526536F 66747761 7265
// --����-I:	QIUSHI-I(QS-I):	51495553 48492D49 2851532D 4929       ; QIUSHI-I(QS-I)
// System boot, please wait ......: 53797374 656D2062 6F6F742C 20706C65 61736520 77616974 202E2E2E 2E2E2E
// College of Computer Science��Zhejiang University:	436F6C6C 65676520 6F662043 6F6D7075 74657220 53636965 6E63652C 5A68656A
// 69616E67 20556E69 76657273 697479
// Copyright 2008-0000.0012:	436F7079 72696768 74203230 30382D30 3030302E 30303132
