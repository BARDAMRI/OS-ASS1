
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	99013103          	ld	sp,-1648(sp) # 80008990 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0fc78793          	addi	a5,a5,252 # 80006160 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	38e080e7          	jalr	910(ra) # 800024ba <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ec080e7          	jalr	2028(ra) # 800019b0 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	e42080e7          	jalr	-446(ra) # 80002016 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	254080e7          	jalr	596(ra) # 80002464 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f7c50513          	addi	a0,a0,-132 # 800111a0 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f6650513          	addi	a0,a0,-154 # 800111a0 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	fcf72323          	sw	a5,-58(a4) # 80011238 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ed450513          	addi	a0,a0,-300 # 800111a0 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	21e080e7          	jalr	542(ra) # 80002510 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	ea650513          	addi	a0,a0,-346 # 800111a0 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e8270713          	addi	a4,a4,-382 # 800111a0 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e5878793          	addi	a5,a5,-424 # 800111a0 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ec27a783          	lw	a5,-318(a5) # 80011238 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	e1670713          	addi	a4,a4,-490 # 800111a0 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	e0648493          	addi	s1,s1,-506 # 800111a0 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	dca70713          	addi	a4,a4,-566 # 800111a0 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e4f72a23          	sw	a5,-428(a4) # 80011240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d8e78793          	addi	a5,a5,-626 # 800111a0 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	e0c7a323          	sw	a2,-506(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dfa50513          	addi	a0,a0,-518 # 80011238 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d5c080e7          	jalr	-676(ra) # 800021a2 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d4050513          	addi	a0,a0,-704 # 800111a0 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	6c078793          	addi	a5,a5,1728 # 80021b38 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	d007ab23          	sw	zero,-746(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	e3450513          	addi	a0,a0,-460 # 800083a0 <digits+0x360>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	ca6dad83          	lw	s11,-858(s11) # 80011260 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c5050513          	addi	a0,a0,-944 # 80011248 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	aec50513          	addi	a0,a0,-1300 # 80011248 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ad048493          	addi	s1,s1,-1328 # 80011248 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a9050513          	addi	a0,a0,-1392 # 80011268 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9fea0a13          	addi	s4,s4,-1538 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	902080e7          	jalr	-1790(ra) # 800021a2 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	98c50513          	addi	a0,a0,-1652 # 80011268 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	958a0a13          	addi	s4,s4,-1704 # 80011268 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00001097          	auipc	ra,0x1
    80000930:	6ea080e7          	jalr	1770(ra) # 80002016 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	92648493          	addi	s1,s1,-1754 # 80011268 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	89e48493          	addi	s1,s1,-1890 # 80011268 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	87490913          	addi	s2,s2,-1932 # 800112a0 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7d850513          	addi	a0,a0,2008 # 800112a0 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	7a248493          	addi	s1,s1,1954 # 800112a0 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	78a50513          	addi	a0,a0,1930 # 800112a0 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	75e50513          	addi	a0,a0,1886 # 800112a0 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	e16080e7          	jalr	-490(ra) # 80001994 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	de4080e7          	jalr	-540(ra) # 80001994 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	dd8080e7          	jalr	-552(ra) # 80001994 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	dc0080e7          	jalr	-576(ra) # 80001994 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	d80080e7          	jalr	-640(ra) # 80001994 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	d54080e7          	jalr	-684(ra) # 80001994 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	aee080e7          	jalr	-1298(ra) # 80001984 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	ad2080e7          	jalr	-1326(ra) # 80001984 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	d0c080e7          	jalr	-756(ra) # 80002be0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	2c4080e7          	jalr	708(ra) # 800061a0 <plicinithart>
  }

  scheduler();        
    80000ee4:	00002097          	auipc	ra,0x2
    80000ee8:	aea080e7          	jalr	-1302(ra) # 800029ce <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	4a450513          	addi	a0,a0,1188 # 800083a0 <digits+0x360>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	48450513          	addi	a0,a0,1156 # 800083a0 <digits+0x360>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	990080e7          	jalr	-1648(ra) # 800018d4 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00002097          	auipc	ra,0x2
    80000f50:	c6c080e7          	jalr	-916(ra) # 80002bb8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	c8c080e7          	jalr	-884(ra) # 80002be0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	22e080e7          	jalr	558(ra) # 8000618a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	23c080e7          	jalr	572(ra) # 800061a0 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	418080e7          	jalr	1048(ra) # 80003384 <binit>
    iinit();         // inode table
    80000f74:	00003097          	auipc	ra,0x3
    80000f78:	aa8080e7          	jalr	-1368(ra) # 80003a1c <iinit>
    fileinit();      // file table
    80000f7c:	00004097          	auipc	ra,0x4
    80000f80:	a52080e7          	jalr	-1454(ra) # 800049ce <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	33e080e7          	jalr	830(ra) # 800062c2 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	d46080e7          	jalr	-698(ra) # 80001cd2 <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	5fe080e7          	jalr	1534(ra) # 8000183e <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    8000183e:	7139                	addi	sp,sp,-64
    80001840:	fc06                	sd	ra,56(sp)
    80001842:	f822                	sd	s0,48(sp)
    80001844:	f426                	sd	s1,40(sp)
    80001846:	f04a                	sd	s2,32(sp)
    80001848:	ec4e                	sd	s3,24(sp)
    8000184a:	e852                	sd	s4,16(sp)
    8000184c:	e456                	sd	s5,8(sp)
    8000184e:	e05a                	sd	s6,0(sp)
    80001850:	0080                	addi	s0,sp,64
    80001852:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001854:	00010497          	auipc	s1,0x10
    80001858:	e9c48493          	addi	s1,s1,-356 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185c:	8b26                	mv	s6,s1
    8000185e:	00006a97          	auipc	s5,0x6
    80001862:	7a2a8a93          	addi	s5,s5,1954 # 80008000 <etext>
    80001866:	04000937          	lui	s2,0x4000
    8000186a:	197d                	addi	s2,s2,-1
    8000186c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	00016a17          	auipc	s4,0x16
    80001872:	082a0a13          	addi	s4,s4,130 # 800178f0 <tickslock>
    char *pa = kalloc();
    80001876:	fffff097          	auipc	ra,0xfffff
    8000187a:	27e080e7          	jalr	638(ra) # 80000af4 <kalloc>
    8000187e:	862a                	mv	a2,a0
    if(pa == 0)
    80001880:	c131                	beqz	a0,800018c4 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001882:	416485b3          	sub	a1,s1,s6
    80001886:	858d                	srai	a1,a1,0x3
    80001888:	000ab783          	ld	a5,0(s5)
    8000188c:	02f585b3          	mul	a1,a1,a5
    80001890:	2585                	addiw	a1,a1,1
    80001892:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001896:	4719                	li	a4,6
    80001898:	6685                	lui	a3,0x1
    8000189a:	40b905b3          	sub	a1,s2,a1
    8000189e:	854e                	mv	a0,s3
    800018a0:	00000097          	auipc	ra,0x0
    800018a4:	8b0080e7          	jalr	-1872(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a8:	18848493          	addi	s1,s1,392
    800018ac:	fd4495e3          	bne	s1,s4,80001876 <proc_mapstacks+0x38>
  }
}
    800018b0:	70e2                	ld	ra,56(sp)
    800018b2:	7442                	ld	s0,48(sp)
    800018b4:	74a2                	ld	s1,40(sp)
    800018b6:	7902                	ld	s2,32(sp)
    800018b8:	69e2                	ld	s3,24(sp)
    800018ba:	6a42                	ld	s4,16(sp)
    800018bc:	6aa2                	ld	s5,8(sp)
    800018be:	6b02                	ld	s6,0(sp)
    800018c0:	6121                	addi	sp,sp,64
    800018c2:	8082                	ret
      panic("kalloc");
    800018c4:	00007517          	auipc	a0,0x7
    800018c8:	91450513          	addi	a0,a0,-1772 # 800081d8 <digits+0x198>
    800018cc:	fffff097          	auipc	ra,0xfffff
    800018d0:	c72080e7          	jalr	-910(ra) # 8000053e <panic>

00000000800018d4 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d4:	7139                	addi	sp,sp,-64
    800018d6:	fc06                	sd	ra,56(sp)
    800018d8:	f822                	sd	s0,48(sp)
    800018da:	f426                	sd	s1,40(sp)
    800018dc:	f04a                	sd	s2,32(sp)
    800018de:	ec4e                	sd	s3,24(sp)
    800018e0:	e852                	sd	s4,16(sp)
    800018e2:	e456                	sd	s5,8(sp)
    800018e4:	e05a                	sd	s6,0(sp)
    800018e6:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e8:	00007597          	auipc	a1,0x7
    800018ec:	8f858593          	addi	a1,a1,-1800 # 800081e0 <digits+0x1a0>
    800018f0:	00010517          	auipc	a0,0x10
    800018f4:	9d050513          	addi	a0,a0,-1584 # 800112c0 <pid_lock>
    800018f8:	fffff097          	auipc	ra,0xfffff
    800018fc:	25c080e7          	jalr	604(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001900:	00007597          	auipc	a1,0x7
    80001904:	8e858593          	addi	a1,a1,-1816 # 800081e8 <digits+0x1a8>
    80001908:	00010517          	auipc	a0,0x10
    8000190c:	9d050513          	addi	a0,a0,-1584 # 800112d8 <wait_lock>
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	244080e7          	jalr	580(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	00010497          	auipc	s1,0x10
    8000191c:	dd848493          	addi	s1,s1,-552 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001920:	00007b17          	auipc	s6,0x7
    80001924:	8d8b0b13          	addi	s6,s6,-1832 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001928:	8aa6                	mv	s5,s1
    8000192a:	00006a17          	auipc	s4,0x6
    8000192e:	6d6a0a13          	addi	s4,s4,1750 # 80008000 <etext>
    80001932:	04000937          	lui	s2,0x4000
    80001936:	197d                	addi	s2,s2,-1
    80001938:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193a:	00016997          	auipc	s3,0x16
    8000193e:	fb698993          	addi	s3,s3,-74 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001942:	85da                	mv	a1,s6
    80001944:	8526                	mv	a0,s1
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	20e080e7          	jalr	526(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000194e:	415487b3          	sub	a5,s1,s5
    80001952:	878d                	srai	a5,a5,0x3
    80001954:	000a3703          	ld	a4,0(s4)
    80001958:	02e787b3          	mul	a5,a5,a4
    8000195c:	2785                	addiw	a5,a5,1
    8000195e:	00d7979b          	slliw	a5,a5,0xd
    80001962:	40f907b3          	sub	a5,s2,a5
    80001966:	f0bc                	sd	a5,96(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001968:	18848493          	addi	s1,s1,392
    8000196c:	fd349be3          	bne	s1,s3,80001942 <procinit+0x6e>
  }
}
    80001970:	70e2                	ld	ra,56(sp)
    80001972:	7442                	ld	s0,48(sp)
    80001974:	74a2                	ld	s1,40(sp)
    80001976:	7902                	ld	s2,32(sp)
    80001978:	69e2                	ld	s3,24(sp)
    8000197a:	6a42                	ld	s4,16(sp)
    8000197c:	6aa2                	ld	s5,8(sp)
    8000197e:	6b02                	ld	s6,0(sp)
    80001980:	6121                	addi	sp,sp,64
    80001982:	8082                	ret

0000000080001984 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001984:	1141                	addi	sp,sp,-16
    80001986:	e422                	sd	s0,8(sp)
    80001988:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198a:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198c:	2501                	sext.w	a0,a0
    8000198e:	6422                	ld	s0,8(sp)
    80001990:	0141                	addi	sp,sp,16
    80001992:	8082                	ret

0000000080001994 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
    8000199a:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199c:	2781                	sext.w	a5,a5
    8000199e:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a0:	00010517          	auipc	a0,0x10
    800019a4:	95050513          	addi	a0,a0,-1712 # 800112f0 <cpus>
    800019a8:	953e                	add	a0,a0,a5
    800019aa:	6422                	ld	s0,8(sp)
    800019ac:	0141                	addi	sp,sp,16
    800019ae:	8082                	ret

00000000800019b0 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b0:	1101                	addi	sp,sp,-32
    800019b2:	ec06                	sd	ra,24(sp)
    800019b4:	e822                	sd	s0,16(sp)
    800019b6:	e426                	sd	s1,8(sp)
    800019b8:	1000                	addi	s0,sp,32
  push_off();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1de080e7          	jalr	478(ra) # 80000b98 <push_off>
    800019c2:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c4:	2781                	sext.w	a5,a5
    800019c6:	079e                	slli	a5,a5,0x7
    800019c8:	00010717          	auipc	a4,0x10
    800019cc:	8f870713          	addi	a4,a4,-1800 # 800112c0 <pid_lock>
    800019d0:	97ba                	add	a5,a5,a4
    800019d2:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	264080e7          	jalr	612(ra) # 80000c38 <pop_off>
  return p;
}
    800019dc:	8526                	mv	a0,s1
    800019de:	60e2                	ld	ra,24(sp)
    800019e0:	6442                	ld	s0,16(sp)
    800019e2:	64a2                	ld	s1,8(sp)
    800019e4:	6105                	addi	sp,sp,32
    800019e6:	8082                	ret

00000000800019e8 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e8:	1141                	addi	sp,sp,-16
    800019ea:	e406                	sd	ra,8(sp)
    800019ec:	e022                	sd	s0,0(sp)
    800019ee:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f0:	00000097          	auipc	ra,0x0
    800019f4:	fc0080e7          	jalr	-64(ra) # 800019b0 <myproc>
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	2a0080e7          	jalr	672(ra) # 80000c98 <release>

  if (first) {
    80001a00:	00007797          	auipc	a5,0x7
    80001a04:	f407a783          	lw	a5,-192(a5) # 80008940 <first.1698>
    80001a08:	eb89                	bnez	a5,80001a1a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0a:	00001097          	auipc	ra,0x1
    80001a0e:	1ee080e7          	jalr	494(ra) # 80002bf8 <usertrapret>
}
    80001a12:	60a2                	ld	ra,8(sp)
    80001a14:	6402                	ld	s0,0(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret
    first = 0;
    80001a1a:	00007797          	auipc	a5,0x7
    80001a1e:	f207a323          	sw	zero,-218(a5) # 80008940 <first.1698>
    fsinit(ROOTDEV);
    80001a22:	4505                	li	a0,1
    80001a24:	00002097          	auipc	ra,0x2
    80001a28:	f78080e7          	jalr	-136(ra) # 8000399c <fsinit>
    80001a2c:	bff9                	j	80001a0a <forkret+0x22>

0000000080001a2e <allocpid>:
allocpid() {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	e04a                	sd	s2,0(sp)
    80001a38:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3a:	00010917          	auipc	s2,0x10
    80001a3e:	88690913          	addi	s2,s2,-1914 # 800112c0 <pid_lock>
    80001a42:	854a                	mv	a0,s2
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1a0080e7          	jalr	416(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001a4c:	00007797          	auipc	a5,0x7
    80001a50:	efc78793          	addi	a5,a5,-260 # 80008948 <nextpid>
    80001a54:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a56:	0014871b          	addiw	a4,s1,1
    80001a5a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5c:	854a                	mv	a0,s2
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	23a080e7          	jalr	570(ra) # 80000c98 <release>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6902                	ld	s2,0(sp)
    80001a70:	6105                	addi	sp,sp,32
    80001a72:	8082                	ret

0000000080001a74 <proc_pagetable>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
    80001a80:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a82:	00000097          	auipc	ra,0x0
    80001a86:	8b8080e7          	jalr	-1864(ra) # 8000133a <uvmcreate>
    80001a8a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8c:	c121                	beqz	a0,80001acc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8e:	4729                	li	a4,10
    80001a90:	00005697          	auipc	a3,0x5
    80001a94:	57068693          	addi	a3,a3,1392 # 80007000 <_trampoline>
    80001a98:	6605                	lui	a2,0x1
    80001a9a:	040005b7          	lui	a1,0x4000
    80001a9e:	15fd                	addi	a1,a1,-1
    80001aa0:	05b2                	slli	a1,a1,0xc
    80001aa2:	fffff097          	auipc	ra,0xfffff
    80001aa6:	60e080e7          	jalr	1550(ra) # 800010b0 <mappages>
    80001aaa:	02054863          	bltz	a0,80001ada <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aae:	4719                	li	a4,6
    80001ab0:	07893683          	ld	a3,120(s2)
    80001ab4:	6605                	lui	a2,0x1
    80001ab6:	020005b7          	lui	a1,0x2000
    80001aba:	15fd                	addi	a1,a1,-1
    80001abc:	05b6                	slli	a1,a1,0xd
    80001abe:	8526                	mv	a0,s1
    80001ac0:	fffff097          	auipc	ra,0xfffff
    80001ac4:	5f0080e7          	jalr	1520(ra) # 800010b0 <mappages>
    80001ac8:	02054163          	bltz	a0,80001aea <proc_pagetable+0x76>
}
    80001acc:	8526                	mv	a0,s1
    80001ace:	60e2                	ld	ra,24(sp)
    80001ad0:	6442                	ld	s0,16(sp)
    80001ad2:	64a2                	ld	s1,8(sp)
    80001ad4:	6902                	ld	s2,0(sp)
    80001ad6:	6105                	addi	sp,sp,32
    80001ad8:	8082                	ret
    uvmfree(pagetable, 0);
    80001ada:	4581                	li	a1,0
    80001adc:	8526                	mv	a0,s1
    80001ade:	00000097          	auipc	ra,0x0
    80001ae2:	a58080e7          	jalr	-1448(ra) # 80001536 <uvmfree>
    return 0;
    80001ae6:	4481                	li	s1,0
    80001ae8:	b7d5                	j	80001acc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aea:	4681                	li	a3,0
    80001aec:	4605                	li	a2,1
    80001aee:	040005b7          	lui	a1,0x4000
    80001af2:	15fd                	addi	a1,a1,-1
    80001af4:	05b2                	slli	a1,a1,0xc
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	77e080e7          	jalr	1918(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b00:	4581                	li	a1,0
    80001b02:	8526                	mv	a0,s1
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	a32080e7          	jalr	-1486(ra) # 80001536 <uvmfree>
    return 0;
    80001b0c:	4481                	li	s1,0
    80001b0e:	bf7d                	j	80001acc <proc_pagetable+0x58>

0000000080001b10 <proc_freepagetable>:
{
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
    80001b1c:	84aa                	mv	s1,a0
    80001b1e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b20:	4681                	li	a3,0
    80001b22:	4605                	li	a2,1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	74a080e7          	jalr	1866(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b34:	4681                	li	a3,0
    80001b36:	4605                	li	a2,1
    80001b38:	020005b7          	lui	a1,0x2000
    80001b3c:	15fd                	addi	a1,a1,-1
    80001b3e:	05b6                	slli	a1,a1,0xd
    80001b40:	8526                	mv	a0,s1
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	734080e7          	jalr	1844(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4a:	85ca                	mv	a1,s2
    80001b4c:	8526                	mv	a0,s1
    80001b4e:	00000097          	auipc	ra,0x0
    80001b52:	9e8080e7          	jalr	-1560(ra) # 80001536 <uvmfree>
}
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6902                	ld	s2,0(sp)
    80001b5e:	6105                	addi	sp,sp,32
    80001b60:	8082                	ret

0000000080001b62 <freeproc>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	1000                	addi	s0,sp,32
    80001b6c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6e:	7d28                	ld	a0,120(a0)
    80001b70:	c509                	beqz	a0,80001b7a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	e86080e7          	jalr	-378(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001b7a:	0604bc23          	sd	zero,120(s1)
  if(p->pagetable)
    80001b7e:	78a8                	ld	a0,112(s1)
    80001b80:	c511                	beqz	a0,80001b8c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b82:	74ac                	ld	a1,104(s1)
    80001b84:	00000097          	auipc	ra,0x0
    80001b88:	f8c080e7          	jalr	-116(ra) # 80001b10 <proc_freepagetable>
  p->pagetable = 0;
    80001b8c:	0604b823          	sd	zero,112(s1)
  p->sz = 0;
    80001b90:	0604b423          	sd	zero,104(s1)
  p->pid = 0;
    80001b94:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b98:	0404bc23          	sd	zero,88(s1)
  p->name[0] = 0;
    80001b9c:	16048c23          	sb	zero,376(s1)
  p->chan = 0;
    80001ba0:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba4:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba8:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bac:	0004ac23          	sw	zero,24(s1)
}
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6105                	addi	sp,sp,32
    80001bb8:	8082                	ret

0000000080001bba <allocproc>:
{
    80001bba:	1101                	addi	sp,sp,-32
    80001bbc:	ec06                	sd	ra,24(sp)
    80001bbe:	e822                	sd	s0,16(sp)
    80001bc0:	e426                	sd	s1,8(sp)
    80001bc2:	e04a                	sd	s2,0(sp)
    80001bc4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc6:	00010497          	auipc	s1,0x10
    80001bca:	b2a48493          	addi	s1,s1,-1238 # 800116f0 <proc>
    80001bce:	00016917          	auipc	s2,0x16
    80001bd2:	d2290913          	addi	s2,s2,-734 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	00c080e7          	jalr	12(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001be0:	4c9c                	lw	a5,24(s1)
    80001be2:	cf81                	beqz	a5,80001bfa <allocproc+0x40>
      release(&p->lock);
    80001be4:	8526                	mv	a0,s1
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	0b2080e7          	jalr	178(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bee:	18848493          	addi	s1,s1,392
    80001bf2:	ff2492e3          	bne	s1,s2,80001bd6 <allocproc+0x1c>
  return 0;
    80001bf6:	4481                	li	s1,0
    80001bf8:	a069                	j	80001c82 <allocproc+0xc8>
  p->pid = allocpid();
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e34080e7          	jalr	-460(ra) # 80001a2e <allocpid>
    80001c02:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c04:	4785                	li	a5,1
    80001c06:	cc9c                	sw	a5,24(s1)
  if (clock_start == 0) 
    80001c08:	00007797          	auipc	a5,0x7
    80001c0c:	4387a783          	lw	a5,1080(a5) # 80009040 <clock_start>
    80001c10:	c3c1                	beqz	a5,80001c90 <allocproc+0xd6>
  p->pid = allocpid();
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	e1c080e7          	jalr	-484(ra) # 80001a2e <allocpid>
    80001c1a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1c:	4785                	li	a5,1
    80001c1e:	cc9c                	sw	a5,24(s1)
  p->mean_ticks = 0;
    80001c20:	0204aa23          	sw	zero,52(s1)
  p->last_ticks = 0;
    80001c24:	0204ac23          	sw	zero,56(s1)
  p->run_time = 0;
    80001c28:	0404a823          	sw	zero,80(s1)
  p->sleep_time = 0;
    80001c2c:	0404a623          	sw	zero,76(s1)
  p->last_sleep_time = 0;
    80001c30:	0404a423          	sw	zero,72(s1)
  p->runnable_time = 0;
    80001c34:	0404aa23          	sw	zero,84(s1)
  p->last_run_time = 0;
    80001c38:	0404a223          	sw	zero,68(s1)
  p->last_runnable_time = 0;
    80001c3c:	0404a023          	sw	zero,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c40:	fffff097          	auipc	ra,0xfffff
    80001c44:	eb4080e7          	jalr	-332(ra) # 80000af4 <kalloc>
    80001c48:	892a                	mv	s2,a0
    80001c4a:	fca8                	sd	a0,120(s1)
    80001c4c:	c939                	beqz	a0,80001ca2 <allocproc+0xe8>
  p->pagetable = proc_pagetable(p);
    80001c4e:	8526                	mv	a0,s1
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	e24080e7          	jalr	-476(ra) # 80001a74 <proc_pagetable>
    80001c58:	892a                	mv	s2,a0
    80001c5a:	f8a8                	sd	a0,112(s1)
  if(p->pagetable == 0){
    80001c5c:	cd39                	beqz	a0,80001cba <allocproc+0x100>
  memset(&p->context, 0, sizeof(p->context));
    80001c5e:	07000613          	li	a2,112
    80001c62:	4581                	li	a1,0
    80001c64:	08048513          	addi	a0,s1,128
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	078080e7          	jalr	120(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001c70:	00000797          	auipc	a5,0x0
    80001c74:	d7878793          	addi	a5,a5,-648 # 800019e8 <forkret>
    80001c78:	e0dc                	sd	a5,128(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c7a:	70bc                	ld	a5,96(s1)
    80001c7c:	6705                	lui	a4,0x1
    80001c7e:	97ba                	add	a5,a5,a4
    80001c80:	e4dc                	sd	a5,136(s1)
}
    80001c82:	8526                	mv	a0,s1
    80001c84:	60e2                	ld	ra,24(sp)
    80001c86:	6442                	ld	s0,16(sp)
    80001c88:	64a2                	ld	s1,8(sp)
    80001c8a:	6902                	ld	s2,0(sp)
    80001c8c:	6105                	addi	sp,sp,32
    80001c8e:	8082                	ret
  clock_start = ticks;
    80001c90:	00007797          	auipc	a5,0x7
    80001c94:	3c87a783          	lw	a5,968(a5) # 80009058 <ticks>
    80001c98:	00007717          	auipc	a4,0x7
    80001c9c:	3af72423          	sw	a5,936(a4) # 80009040 <clock_start>
    80001ca0:	bf8d                	j	80001c12 <allocproc+0x58>
    freeproc(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	ebe080e7          	jalr	-322(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	fea080e7          	jalr	-22(ra) # 80000c98 <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	b7e9                	j	80001c82 <allocproc+0xc8>
    freeproc(p);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	ea6080e7          	jalr	-346(ra) # 80001b62 <freeproc>
    release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	fd2080e7          	jalr	-46(ra) # 80000c98 <release>
    return 0;
    80001cce:	84ca                	mv	s1,s2
    80001cd0:	bf4d                	j	80001c82 <allocproc+0xc8>

0000000080001cd2 <userinit>:
{
    80001cd2:	1101                	addi	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	ede080e7          	jalr	-290(ra) # 80001bba <allocproc>
    80001ce4:	84aa                	mv	s1,a0
  initproc = p;
    80001ce6:	00007797          	auipc	a5,0x7
    80001cea:	36a7b523          	sd	a0,874(a5) # 80009050 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cee:	03400613          	li	a2,52
    80001cf2:	00007597          	auipc	a1,0x7
    80001cf6:	c5e58593          	addi	a1,a1,-930 # 80008950 <initcode>
    80001cfa:	7928                	ld	a0,112(a0)
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	66c080e7          	jalr	1644(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d04:	6785                	lui	a5,0x1
    80001d06:	f4bc                	sd	a5,104(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d08:	7cb8                	ld	a4,120(s1)
    80001d0a:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0e:	7cb8                	ld	a4,120(s1)
    80001d10:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d12:	4641                	li	a2,16
    80001d14:	00006597          	auipc	a1,0x6
    80001d18:	4ec58593          	addi	a1,a1,1260 # 80008200 <digits+0x1c0>
    80001d1c:	17848513          	addi	a0,s1,376
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	112080e7          	jalr	274(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001d28:	00006517          	auipc	a0,0x6
    80001d2c:	4e850513          	addi	a0,a0,1256 # 80008210 <digits+0x1d0>
    80001d30:	00002097          	auipc	ra,0x2
    80001d34:	69a080e7          	jalr	1690(ra) # 800043ca <namei>
    80001d38:	16a4b823          	sd	a0,368(s1)
  p->state = RUNNABLE;
    80001d3c:	478d                	li	a5,3
    80001d3e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f56080e7          	jalr	-170(ra) # 80000c98 <release>
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret

0000000080001d54 <growproc>:
{
    80001d54:	1101                	addi	sp,sp,-32
    80001d56:	ec06                	sd	ra,24(sp)
    80001d58:	e822                	sd	s0,16(sp)
    80001d5a:	e426                	sd	s1,8(sp)
    80001d5c:	e04a                	sd	s2,0(sp)
    80001d5e:	1000                	addi	s0,sp,32
    80001d60:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d62:	00000097          	auipc	ra,0x0
    80001d66:	c4e080e7          	jalr	-946(ra) # 800019b0 <myproc>
    80001d6a:	892a                	mv	s2,a0
  sz = p->sz;
    80001d6c:	752c                	ld	a1,104(a0)
    80001d6e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d72:	00904f63          	bgtz	s1,80001d90 <growproc+0x3c>
  } else if(n < 0){
    80001d76:	0204cc63          	bltz	s1,80001dae <growproc+0x5a>
  p->sz = sz;
    80001d7a:	1602                	slli	a2,a2,0x20
    80001d7c:	9201                	srli	a2,a2,0x20
    80001d7e:	06c93423          	sd	a2,104(s2)
  return 0;
    80001d82:	4501                	li	a0,0
}
    80001d84:	60e2                	ld	ra,24(sp)
    80001d86:	6442                	ld	s0,16(sp)
    80001d88:	64a2                	ld	s1,8(sp)
    80001d8a:	6902                	ld	s2,0(sp)
    80001d8c:	6105                	addi	sp,sp,32
    80001d8e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d90:	9e25                	addw	a2,a2,s1
    80001d92:	1602                	slli	a2,a2,0x20
    80001d94:	9201                	srli	a2,a2,0x20
    80001d96:	1582                	slli	a1,a1,0x20
    80001d98:	9181                	srli	a1,a1,0x20
    80001d9a:	7928                	ld	a0,112(a0)
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	686080e7          	jalr	1670(ra) # 80001422 <uvmalloc>
    80001da4:	0005061b          	sext.w	a2,a0
    80001da8:	fa69                	bnez	a2,80001d7a <growproc+0x26>
      return -1;
    80001daa:	557d                	li	a0,-1
    80001dac:	bfe1                	j	80001d84 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dae:	9e25                	addw	a2,a2,s1
    80001db0:	1602                	slli	a2,a2,0x20
    80001db2:	9201                	srli	a2,a2,0x20
    80001db4:	1582                	slli	a1,a1,0x20
    80001db6:	9181                	srli	a1,a1,0x20
    80001db8:	7928                	ld	a0,112(a0)
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	620080e7          	jalr	1568(ra) # 800013da <uvmdealloc>
    80001dc2:	0005061b          	sext.w	a2,a0
    80001dc6:	bf55                	j	80001d7a <growproc+0x26>

0000000080001dc8 <fork>:
{
    80001dc8:	7179                	addi	sp,sp,-48
    80001dca:	f406                	sd	ra,40(sp)
    80001dcc:	f022                	sd	s0,32(sp)
    80001dce:	ec26                	sd	s1,24(sp)
    80001dd0:	e84a                	sd	s2,16(sp)
    80001dd2:	e44e                	sd	s3,8(sp)
    80001dd4:	e052                	sd	s4,0(sp)
    80001dd6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	bd8080e7          	jalr	-1064(ra) # 800019b0 <myproc>
    80001de0:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001de2:	00000097          	auipc	ra,0x0
    80001de6:	dd8080e7          	jalr	-552(ra) # 80001bba <allocproc>
    80001dea:	10050b63          	beqz	a0,80001f00 <fork+0x138>
    80001dee:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df0:	06893603          	ld	a2,104(s2)
    80001df4:	792c                	ld	a1,112(a0)
    80001df6:	07093503          	ld	a0,112(s2)
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	774080e7          	jalr	1908(ra) # 8000156e <uvmcopy>
    80001e02:	04054663          	bltz	a0,80001e4e <fork+0x86>
  np->sz = p->sz;
    80001e06:	06893783          	ld	a5,104(s2)
    80001e0a:	06f9b423          	sd	a5,104(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e0e:	07893683          	ld	a3,120(s2)
    80001e12:	87b6                	mv	a5,a3
    80001e14:	0789b703          	ld	a4,120(s3)
    80001e18:	12068693          	addi	a3,a3,288
    80001e1c:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e20:	6788                	ld	a0,8(a5)
    80001e22:	6b8c                	ld	a1,16(a5)
    80001e24:	6f90                	ld	a2,24(a5)
    80001e26:	01073023          	sd	a6,0(a4)
    80001e2a:	e708                	sd	a0,8(a4)
    80001e2c:	eb0c                	sd	a1,16(a4)
    80001e2e:	ef10                	sd	a2,24(a4)
    80001e30:	02078793          	addi	a5,a5,32
    80001e34:	02070713          	addi	a4,a4,32
    80001e38:	fed792e3          	bne	a5,a3,80001e1c <fork+0x54>
  np->trapframe->a0 = 0;
    80001e3c:	0789b783          	ld	a5,120(s3)
    80001e40:	0607b823          	sd	zero,112(a5)
    80001e44:	0f000493          	li	s1,240
  for(i = 0; i < NOFILE; i++)
    80001e48:	17000a13          	li	s4,368
    80001e4c:	a03d                	j	80001e7a <fork+0xb2>
    freeproc(np);
    80001e4e:	854e                	mv	a0,s3
    80001e50:	00000097          	auipc	ra,0x0
    80001e54:	d12080e7          	jalr	-750(ra) # 80001b62 <freeproc>
    release(&np->lock);
    80001e58:	854e                	mv	a0,s3
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	e3e080e7          	jalr	-450(ra) # 80000c98 <release>
    return -1;
    80001e62:	5a7d                	li	s4,-1
    80001e64:	a069                	j	80001eee <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e66:	00003097          	auipc	ra,0x3
    80001e6a:	bfa080e7          	jalr	-1030(ra) # 80004a60 <filedup>
    80001e6e:	009987b3          	add	a5,s3,s1
    80001e72:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e74:	04a1                	addi	s1,s1,8
    80001e76:	01448763          	beq	s1,s4,80001e84 <fork+0xbc>
    if(p->ofile[i])
    80001e7a:	009907b3          	add	a5,s2,s1
    80001e7e:	6388                	ld	a0,0(a5)
    80001e80:	f17d                	bnez	a0,80001e66 <fork+0x9e>
    80001e82:	bfcd                	j	80001e74 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e84:	17093503          	ld	a0,368(s2)
    80001e88:	00002097          	auipc	ra,0x2
    80001e8c:	d4e080e7          	jalr	-690(ra) # 80003bd6 <idup>
    80001e90:	16a9b823          	sd	a0,368(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e94:	4641                	li	a2,16
    80001e96:	17890593          	addi	a1,s2,376
    80001e9a:	17898513          	addi	a0,s3,376
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	f94080e7          	jalr	-108(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001ea6:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001eaa:	854e                	mv	a0,s3
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	dec080e7          	jalr	-532(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001eb4:	0000f497          	auipc	s1,0xf
    80001eb8:	42448493          	addi	s1,s1,1060 # 800112d8 <wait_lock>
    80001ebc:	8526                	mv	a0,s1
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	d26080e7          	jalr	-730(ra) # 80000be4 <acquire>
  np->parent = p;
    80001ec6:	0529bc23          	sd	s2,88(s3)
  release(&wait_lock);
    80001eca:	8526                	mv	a0,s1
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	dcc080e7          	jalr	-564(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001ed4:	854e                	mv	a0,s3
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	d0e080e7          	jalr	-754(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001ede:	478d                	li	a5,3
    80001ee0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee4:	854e                	mv	a0,s3
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	db2080e7          	jalr	-590(ra) # 80000c98 <release>
}
    80001eee:	8552                	mv	a0,s4
    80001ef0:	70a2                	ld	ra,40(sp)
    80001ef2:	7402                	ld	s0,32(sp)
    80001ef4:	64e2                	ld	s1,24(sp)
    80001ef6:	6942                	ld	s2,16(sp)
    80001ef8:	69a2                	ld	s3,8(sp)
    80001efa:	6a02                	ld	s4,0(sp)
    80001efc:	6145                	addi	sp,sp,48
    80001efe:	8082                	ret
    return -1;
    80001f00:	5a7d                	li	s4,-1
    80001f02:	b7f5                	j	80001eee <fork+0x126>

0000000080001f04 <sched>:
{
    80001f04:	7179                	addi	sp,sp,-48
    80001f06:	f406                	sd	ra,40(sp)
    80001f08:	f022                	sd	s0,32(sp)
    80001f0a:	ec26                	sd	s1,24(sp)
    80001f0c:	e84a                	sd	s2,16(sp)
    80001f0e:	e44e                	sd	s3,8(sp)
    80001f10:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f12:	00000097          	auipc	ra,0x0
    80001f16:	a9e080e7          	jalr	-1378(ra) # 800019b0 <myproc>
    80001f1a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	c4e080e7          	jalr	-946(ra) # 80000b6a <holding>
    80001f24:	c93d                	beqz	a0,80001f9a <sched+0x96>
    80001f26:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f28:	2781                	sext.w	a5,a5
    80001f2a:	079e                	slli	a5,a5,0x7
    80001f2c:	0000f717          	auipc	a4,0xf
    80001f30:	39470713          	addi	a4,a4,916 # 800112c0 <pid_lock>
    80001f34:	97ba                	add	a5,a5,a4
    80001f36:	0a87a703          	lw	a4,168(a5)
    80001f3a:	4785                	li	a5,1
    80001f3c:	06f71763          	bne	a4,a5,80001faa <sched+0xa6>
  if(p->state == RUNNING)
    80001f40:	4c98                	lw	a4,24(s1)
    80001f42:	4791                	li	a5,4
    80001f44:	06f70b63          	beq	a4,a5,80001fba <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f4e:	efb5                	bnez	a5,80001fca <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f50:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f52:	0000f917          	auipc	s2,0xf
    80001f56:	36e90913          	addi	s2,s2,878 # 800112c0 <pid_lock>
    80001f5a:	2781                	sext.w	a5,a5
    80001f5c:	079e                	slli	a5,a5,0x7
    80001f5e:	97ca                	add	a5,a5,s2
    80001f60:	0ac7a983          	lw	s3,172(a5)
    80001f64:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f597          	auipc	a1,0xf
    80001f6e:	38e58593          	addi	a1,a1,910 # 800112f8 <cpus+0x8>
    80001f72:	95be                	add	a1,a1,a5
    80001f74:	08048513          	addi	a0,s1,128
    80001f78:	00001097          	auipc	ra,0x1
    80001f7c:	bd6080e7          	jalr	-1066(ra) # 80002b4e <swtch>
    80001f80:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f82:	2781                	sext.w	a5,a5
    80001f84:	079e                	slli	a5,a5,0x7
    80001f86:	97ca                	add	a5,a5,s2
    80001f88:	0b37a623          	sw	s3,172(a5)
}
    80001f8c:	70a2                	ld	ra,40(sp)
    80001f8e:	7402                	ld	s0,32(sp)
    80001f90:	64e2                	ld	s1,24(sp)
    80001f92:	6942                	ld	s2,16(sp)
    80001f94:	69a2                	ld	s3,8(sp)
    80001f96:	6145                	addi	sp,sp,48
    80001f98:	8082                	ret
    panic("sched p->lock");
    80001f9a:	00006517          	auipc	a0,0x6
    80001f9e:	27e50513          	addi	a0,a0,638 # 80008218 <digits+0x1d8>
    80001fa2:	ffffe097          	auipc	ra,0xffffe
    80001fa6:	59c080e7          	jalr	1436(ra) # 8000053e <panic>
    panic("sched locks");
    80001faa:	00006517          	auipc	a0,0x6
    80001fae:	27e50513          	addi	a0,a0,638 # 80008228 <digits+0x1e8>
    80001fb2:	ffffe097          	auipc	ra,0xffffe
    80001fb6:	58c080e7          	jalr	1420(ra) # 8000053e <panic>
    panic("sched running");
    80001fba:	00006517          	auipc	a0,0x6
    80001fbe:	27e50513          	addi	a0,a0,638 # 80008238 <digits+0x1f8>
    80001fc2:	ffffe097          	auipc	ra,0xffffe
    80001fc6:	57c080e7          	jalr	1404(ra) # 8000053e <panic>
    panic("sched interruptible");
    80001fca:	00006517          	auipc	a0,0x6
    80001fce:	27e50513          	addi	a0,a0,638 # 80008248 <digits+0x208>
    80001fd2:	ffffe097          	auipc	ra,0xffffe
    80001fd6:	56c080e7          	jalr	1388(ra) # 8000053e <panic>

0000000080001fda <yield>:
{
    80001fda:	1101                	addi	sp,sp,-32
    80001fdc:	ec06                	sd	ra,24(sp)
    80001fde:	e822                	sd	s0,16(sp)
    80001fe0:	e426                	sd	s1,8(sp)
    80001fe2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001fe4:	00000097          	auipc	ra,0x0
    80001fe8:	9cc080e7          	jalr	-1588(ra) # 800019b0 <myproc>
    80001fec:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001fee:	fffff097          	auipc	ra,0xfffff
    80001ff2:	bf6080e7          	jalr	-1034(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80001ff6:	478d                	li	a5,3
    80001ff8:	cc9c                	sw	a5,24(s1)
  sched();
    80001ffa:	00000097          	auipc	ra,0x0
    80001ffe:	f0a080e7          	jalr	-246(ra) # 80001f04 <sched>
  release(&p->lock);
    80002002:	8526                	mv	a0,s1
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	c94080e7          	jalr	-876(ra) # 80000c98 <release>
}
    8000200c:	60e2                	ld	ra,24(sp)
    8000200e:	6442                	ld	s0,16(sp)
    80002010:	64a2                	ld	s1,8(sp)
    80002012:	6105                	addi	sp,sp,32
    80002014:	8082                	ret

0000000080002016 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002016:	7179                	addi	sp,sp,-48
    80002018:	f406                	sd	ra,40(sp)
    8000201a:	f022                	sd	s0,32(sp)
    8000201c:	ec26                	sd	s1,24(sp)
    8000201e:	e84a                	sd	s2,16(sp)
    80002020:	e44e                	sd	s3,8(sp)
    80002022:	1800                	addi	s0,sp,48
    80002024:	89aa                	mv	s3,a0
    80002026:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	988080e7          	jalr	-1656(ra) # 800019b0 <myproc>
    80002030:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002032:	fffff097          	auipc	ra,0xfffff
    80002036:	bb2080e7          	jalr	-1102(ra) # 80000be4 <acquire>
  release(lk);
    8000203a:	854a                	mv	a0,s2
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c5c080e7          	jalr	-932(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    80002044:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002048:	4789                	li	a5,2
    8000204a:	cc9c                	sw	a5,24(s1)

  sched();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	eb8080e7          	jalr	-328(ra) # 80001f04 <sched>

  // Tidy up.
  p->chan = 0;
    80002054:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c3e080e7          	jalr	-962(ra) # 80000c98 <release>
  acquire(lk);
    80002062:	854a                	mv	a0,s2
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	b80080e7          	jalr	-1152(ra) # 80000be4 <acquire>
}
    8000206c:	70a2                	ld	ra,40(sp)
    8000206e:	7402                	ld	s0,32(sp)
    80002070:	64e2                	ld	s1,24(sp)
    80002072:	6942                	ld	s2,16(sp)
    80002074:	69a2                	ld	s3,8(sp)
    80002076:	6145                	addi	sp,sp,48
    80002078:	8082                	ret

000000008000207a <wait>:
{
    8000207a:	715d                	addi	sp,sp,-80
    8000207c:	e486                	sd	ra,72(sp)
    8000207e:	e0a2                	sd	s0,64(sp)
    80002080:	fc26                	sd	s1,56(sp)
    80002082:	f84a                	sd	s2,48(sp)
    80002084:	f44e                	sd	s3,40(sp)
    80002086:	f052                	sd	s4,32(sp)
    80002088:	ec56                	sd	s5,24(sp)
    8000208a:	e85a                	sd	s6,16(sp)
    8000208c:	e45e                	sd	s7,8(sp)
    8000208e:	e062                	sd	s8,0(sp)
    80002090:	0880                	addi	s0,sp,80
    80002092:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	91c080e7          	jalr	-1764(ra) # 800019b0 <myproc>
    8000209c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000209e:	0000f517          	auipc	a0,0xf
    800020a2:	23a50513          	addi	a0,a0,570 # 800112d8 <wait_lock>
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	b3e080e7          	jalr	-1218(ra) # 80000be4 <acquire>
    havekids = 0;
    800020ae:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800020b0:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800020b2:	00016997          	auipc	s3,0x16
    800020b6:	83e98993          	addi	s3,s3,-1986 # 800178f0 <tickslock>
        havekids = 1;
    800020ba:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800020bc:	0000fc17          	auipc	s8,0xf
    800020c0:	21cc0c13          	addi	s8,s8,540 # 800112d8 <wait_lock>
    havekids = 0;
    800020c4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800020c6:	0000f497          	auipc	s1,0xf
    800020ca:	62a48493          	addi	s1,s1,1578 # 800116f0 <proc>
    800020ce:	a0bd                	j	8000213c <wait+0xc2>
          pid = np->pid;
    800020d0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800020d4:	000b0e63          	beqz	s6,800020f0 <wait+0x76>
    800020d8:	4691                	li	a3,4
    800020da:	02c48613          	addi	a2,s1,44
    800020de:	85da                	mv	a1,s6
    800020e0:	07093503          	ld	a0,112(s2)
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	58e080e7          	jalr	1422(ra) # 80001672 <copyout>
    800020ec:	02054563          	bltz	a0,80002116 <wait+0x9c>
          freeproc(np);
    800020f0:	8526                	mv	a0,s1
    800020f2:	00000097          	auipc	ra,0x0
    800020f6:	a70080e7          	jalr	-1424(ra) # 80001b62 <freeproc>
          release(&np->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	b9c080e7          	jalr	-1124(ra) # 80000c98 <release>
          release(&wait_lock);
    80002104:	0000f517          	auipc	a0,0xf
    80002108:	1d450513          	addi	a0,a0,468 # 800112d8 <wait_lock>
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b8c080e7          	jalr	-1140(ra) # 80000c98 <release>
          return pid;
    80002114:	a09d                	j	8000217a <wait+0x100>
            release(&np->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	b80080e7          	jalr	-1152(ra) # 80000c98 <release>
            release(&wait_lock);
    80002120:	0000f517          	auipc	a0,0xf
    80002124:	1b850513          	addi	a0,a0,440 # 800112d8 <wait_lock>
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b70080e7          	jalr	-1168(ra) # 80000c98 <release>
            return -1;
    80002130:	59fd                	li	s3,-1
    80002132:	a0a1                	j	8000217a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002134:	18848493          	addi	s1,s1,392
    80002138:	03348463          	beq	s1,s3,80002160 <wait+0xe6>
      if(np->parent == p){
    8000213c:	6cbc                	ld	a5,88(s1)
    8000213e:	ff279be3          	bne	a5,s2,80002134 <wait+0xba>
        acquire(&np->lock);
    80002142:	8526                	mv	a0,s1
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	aa0080e7          	jalr	-1376(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    8000214c:	4c9c                	lw	a5,24(s1)
    8000214e:	f94781e3          	beq	a5,s4,800020d0 <wait+0x56>
        release(&np->lock);
    80002152:	8526                	mv	a0,s1
    80002154:	fffff097          	auipc	ra,0xfffff
    80002158:	b44080e7          	jalr	-1212(ra) # 80000c98 <release>
        havekids = 1;
    8000215c:	8756                	mv	a4,s5
    8000215e:	bfd9                	j	80002134 <wait+0xba>
    if(!havekids || p->killed){
    80002160:	c701                	beqz	a4,80002168 <wait+0xee>
    80002162:	02892783          	lw	a5,40(s2)
    80002166:	c79d                	beqz	a5,80002194 <wait+0x11a>
      release(&wait_lock);
    80002168:	0000f517          	auipc	a0,0xf
    8000216c:	17050513          	addi	a0,a0,368 # 800112d8 <wait_lock>
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	b28080e7          	jalr	-1240(ra) # 80000c98 <release>
      return -1;
    80002178:	59fd                	li	s3,-1
}
    8000217a:	854e                	mv	a0,s3
    8000217c:	60a6                	ld	ra,72(sp)
    8000217e:	6406                	ld	s0,64(sp)
    80002180:	74e2                	ld	s1,56(sp)
    80002182:	7942                	ld	s2,48(sp)
    80002184:	79a2                	ld	s3,40(sp)
    80002186:	7a02                	ld	s4,32(sp)
    80002188:	6ae2                	ld	s5,24(sp)
    8000218a:	6b42                	ld	s6,16(sp)
    8000218c:	6ba2                	ld	s7,8(sp)
    8000218e:	6c02                	ld	s8,0(sp)
    80002190:	6161                	addi	sp,sp,80
    80002192:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002194:	85e2                	mv	a1,s8
    80002196:	854a                	mv	a0,s2
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	e7e080e7          	jalr	-386(ra) # 80002016 <sleep>
    havekids = 0;
    800021a0:	b715                	j	800020c4 <wait+0x4a>

00000000800021a2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021a2:	7139                	addi	sp,sp,-64
    800021a4:	fc06                	sd	ra,56(sp)
    800021a6:	f822                	sd	s0,48(sp)
    800021a8:	f426                	sd	s1,40(sp)
    800021aa:	f04a                	sd	s2,32(sp)
    800021ac:	ec4e                	sd	s3,24(sp)
    800021ae:	e852                	sd	s4,16(sp)
    800021b0:	e456                	sd	s5,8(sp)
    800021b2:	0080                	addi	s0,sp,64
    800021b4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021b6:	0000f497          	auipc	s1,0xf
    800021ba:	53a48493          	addi	s1,s1,1338 # 800116f0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800021be:	4989                	li	s3,2
        p->state = RUNNABLE;
    800021c0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021c2:	00015917          	auipc	s2,0x15
    800021c6:	72e90913          	addi	s2,s2,1838 # 800178f0 <tickslock>
    800021ca:	a821                	j	800021e2 <wakeup+0x40>
        p->state = RUNNABLE;
    800021cc:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	ac6080e7          	jalr	-1338(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021da:	18848493          	addi	s1,s1,392
    800021de:	03248463          	beq	s1,s2,80002206 <wakeup+0x64>
    if(p != myproc()){
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	7ce080e7          	jalr	1998(ra) # 800019b0 <myproc>
    800021ea:	fea488e3          	beq	s1,a0,800021da <wakeup+0x38>
      acquire(&p->lock);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	9f4080e7          	jalr	-1548(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021f8:	4c9c                	lw	a5,24(s1)
    800021fa:	fd379be3          	bne	a5,s3,800021d0 <wakeup+0x2e>
    800021fe:	709c                	ld	a5,32(s1)
    80002200:	fd4798e3          	bne	a5,s4,800021d0 <wakeup+0x2e>
    80002204:	b7e1                	j	800021cc <wakeup+0x2a>
    }
  }
}
    80002206:	70e2                	ld	ra,56(sp)
    80002208:	7442                	ld	s0,48(sp)
    8000220a:	74a2                	ld	s1,40(sp)
    8000220c:	7902                	ld	s2,32(sp)
    8000220e:	69e2                	ld	s3,24(sp)
    80002210:	6a42                	ld	s4,16(sp)
    80002212:	6aa2                	ld	s5,8(sp)
    80002214:	6121                	addi	sp,sp,64
    80002216:	8082                	ret

0000000080002218 <reparent>:
{
    80002218:	7179                	addi	sp,sp,-48
    8000221a:	f406                	sd	ra,40(sp)
    8000221c:	f022                	sd	s0,32(sp)
    8000221e:	ec26                	sd	s1,24(sp)
    80002220:	e84a                	sd	s2,16(sp)
    80002222:	e44e                	sd	s3,8(sp)
    80002224:	e052                	sd	s4,0(sp)
    80002226:	1800                	addi	s0,sp,48
    80002228:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222a:	0000f497          	auipc	s1,0xf
    8000222e:	4c648493          	addi	s1,s1,1222 # 800116f0 <proc>
      pp->parent = initproc;
    80002232:	00007a17          	auipc	s4,0x7
    80002236:	e1ea0a13          	addi	s4,s4,-482 # 80009050 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000223a:	00015997          	auipc	s3,0x15
    8000223e:	6b698993          	addi	s3,s3,1718 # 800178f0 <tickslock>
    80002242:	a029                	j	8000224c <reparent+0x34>
    80002244:	18848493          	addi	s1,s1,392
    80002248:	01348d63          	beq	s1,s3,80002262 <reparent+0x4a>
    if(pp->parent == p){
    8000224c:	6cbc                	ld	a5,88(s1)
    8000224e:	ff279be3          	bne	a5,s2,80002244 <reparent+0x2c>
      pp->parent = initproc;
    80002252:	000a3503          	ld	a0,0(s4)
    80002256:	eca8                	sd	a0,88(s1)
      wakeup(initproc);
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	f4a080e7          	jalr	-182(ra) # 800021a2 <wakeup>
    80002260:	b7d5                	j	80002244 <reparent+0x2c>
}
    80002262:	70a2                	ld	ra,40(sp)
    80002264:	7402                	ld	s0,32(sp)
    80002266:	64e2                	ld	s1,24(sp)
    80002268:	6942                	ld	s2,16(sp)
    8000226a:	69a2                	ld	s3,8(sp)
    8000226c:	6a02                	ld	s4,0(sp)
    8000226e:	6145                	addi	sp,sp,48
    80002270:	8082                	ret

0000000080002272 <exit>:
{
    80002272:	7179                	addi	sp,sp,-48
    80002274:	f406                	sd	ra,40(sp)
    80002276:	f022                	sd	s0,32(sp)
    80002278:	ec26                	sd	s1,24(sp)
    8000227a:	e84a                	sd	s2,16(sp)
    8000227c:	e44e                	sd	s3,8(sp)
    8000227e:	e052                	sd	s4,0(sp)
    80002280:	1800                	addi	s0,sp,48
    80002282:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	72c080e7          	jalr	1836(ra) # 800019b0 <myproc>
    8000228c:	892a                	mv	s2,a0
  if(p == initproc)
    8000228e:	00007797          	auipc	a5,0x7
    80002292:	dc27b783          	ld	a5,-574(a5) # 80009050 <initproc>
    80002296:	0f050493          	addi	s1,a0,240
    8000229a:	17050993          	addi	s3,a0,368
    8000229e:	02a79363          	bne	a5,a0,800022c4 <exit+0x52>
    panic("init exiting");
    800022a2:	00006517          	auipc	a0,0x6
    800022a6:	fbe50513          	addi	a0,a0,-66 # 80008260 <digits+0x220>
    800022aa:	ffffe097          	auipc	ra,0xffffe
    800022ae:	294080e7          	jalr	660(ra) # 8000053e <panic>
      fileclose(f);
    800022b2:	00003097          	auipc	ra,0x3
    800022b6:	800080e7          	jalr	-2048(ra) # 80004ab2 <fileclose>
      p->ofile[fd] = 0;
    800022ba:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022be:	04a1                	addi	s1,s1,8
    800022c0:	01348563          	beq	s1,s3,800022ca <exit+0x58>
    if(p->ofile[fd]){
    800022c4:	6088                	ld	a0,0(s1)
    800022c6:	f575                	bnez	a0,800022b2 <exit+0x40>
    800022c8:	bfdd                	j	800022be <exit+0x4c>
  begin_op();
    800022ca:	00002097          	auipc	ra,0x2
    800022ce:	31c080e7          	jalr	796(ra) # 800045e6 <begin_op>
  iput(p->cwd);
    800022d2:	17093503          	ld	a0,368(s2)
    800022d6:	00002097          	auipc	ra,0x2
    800022da:	af8080e7          	jalr	-1288(ra) # 80003dce <iput>
  end_op();
    800022de:	00002097          	auipc	ra,0x2
    800022e2:	388080e7          	jalr	904(ra) # 80004666 <end_op>
  p->cwd = 0;
    800022e6:	16093823          	sd	zero,368(s2)
  acquire(&wait_lock);
    800022ea:	0000f517          	auipc	a0,0xf
    800022ee:	fee50513          	addi	a0,a0,-18 # 800112d8 <wait_lock>
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8f2080e7          	jalr	-1806(ra) # 80000be4 <acquire>
  reparent(p);
    800022fa:	854a                	mv	a0,s2
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	f1c080e7          	jalr	-228(ra) # 80002218 <reparent>
  wakeup(p->parent);
    80002304:	05893503          	ld	a0,88(s2)
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	e9a080e7          	jalr	-358(ra) # 800021a2 <wakeup>
  acquire(&p->lock);
    80002310:	854a                	mv	a0,s2
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	8d2080e7          	jalr	-1838(ra) # 80000be4 <acquire>
  if(p->pid != 1 && p->pid!= 2) { 
    8000231a:	03092783          	lw	a5,48(s2)
    8000231e:	37fd                	addiw	a5,a5,-1
    80002320:	4705                	li	a4,1
    80002322:	00f77b63          	bgeu	a4,a5,80002338 <exit+0xc6>
    program_time = program_time + p->run_time;
    80002326:	00007717          	auipc	a4,0x7
    8000232a:	d0670713          	addi	a4,a4,-762 # 8000902c <program_time>
    8000232e:	05092783          	lw	a5,80(s2)
    80002332:	4314                	lw	a3,0(a4)
    80002334:	9fb5                	addw	a5,a5,a3
    80002336:	c31c                	sw	a5,0(a4)
  uint time= number_of_processes* running_processes_mean;
    80002338:	00007597          	auipc	a1,0x7
    8000233c:	cf858593          	addi	a1,a1,-776 # 80009030 <number_of_processes>
    80002340:	419c                	lw	a5,0(a1)
    80002342:	00007617          	auipc	a2,0x7
    80002346:	cf260613          	addi	a2,a2,-782 # 80009034 <running_processes_mean>
    8000234a:	4218                	lw	a4,0(a2)
    8000234c:	02f706bb          	mulw	a3,a4,a5
  time= time+( p->run_time);
    80002350:	05092703          	lw	a4,80(s2)
    80002354:	9f35                	addw	a4,a4,a3
  number_of_processes=number_of_processes+1;
    80002356:	0017869b          	addiw	a3,a5,1
    8000235a:	c194                	sw	a3,0(a1)
  running_processes_mean = time/number_of_processes;
    8000235c:	02d7573b          	divuw	a4,a4,a3
    80002360:	c218                	sw	a4,0(a2)
  time= (number_of_processes-1)*runnable_processes_mean;
    80002362:	00007597          	auipc	a1,0x7
    80002366:	cd658593          	addi	a1,a1,-810 # 80009038 <runnable_processes_mean>
    8000236a:	4198                	lw	a4,0(a1)
    8000236c:	02f7063b          	mulw	a2,a4,a5
  time+= p->runnable_time;
    80002370:	05492703          	lw	a4,84(s2)
    80002374:	9f31                	addw	a4,a4,a2
  runnable_processes_mean= time/(number_of_processes);
    80002376:	02d7573b          	divuw	a4,a4,a3
    8000237a:	c198                	sw	a4,0(a1)
  time= (number_of_processes-1)*runnable_processes_mean;
    8000237c:	02e787bb          	mulw	a5,a5,a4
  time+= p->sleep_time;
    80002380:	04c92703          	lw	a4,76(s2)
    80002384:	9fb9                	addw	a5,a5,a4
  sleeping_processes_mean= time/(number_of_processes);
    80002386:	02d7d7bb          	divuw	a5,a5,a3
    8000238a:	00007717          	auipc	a4,0x7
    8000238e:	caf72923          	sw	a5,-846(a4) # 8000903c <sleeping_processes_mean>
cpuUse=(100*program_time);
    80002392:	06400793          	li	a5,100
    80002396:	00007717          	auipc	a4,0x7
    8000239a:	c9672703          	lw	a4,-874(a4) # 8000902c <program_time>
    8000239e:	02e787bb          	mulw	a5,a5,a4
cpuUse=cpuUse/(tickNow-clock_start);
    800023a2:	00007717          	auipc	a4,0x7
    800023a6:	cb672703          	lw	a4,-842(a4) # 80009058 <ticks>
    800023aa:	00007697          	auipc	a3,0x7
    800023ae:	c966a683          	lw	a3,-874(a3) # 80009040 <clock_start>
    800023b2:	9f15                	subw	a4,a4,a3
    800023b4:	02e7d7bb          	divuw	a5,a5,a4
    800023b8:	00007717          	auipc	a4,0x7
    800023bc:	c6f72823          	sw	a5,-912(a4) # 80009028 <cpuUse>
  p->xstate = status;
    800023c0:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    800023c4:	4795                	li	a5,5
    800023c6:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    800023ca:	0000f517          	auipc	a0,0xf
    800023ce:	f0e50513          	addi	a0,a0,-242 # 800112d8 <wait_lock>
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	8c6080e7          	jalr	-1850(ra) # 80000c98 <release>
  sched();
    800023da:	00000097          	auipc	ra,0x0
    800023de:	b2a080e7          	jalr	-1238(ra) # 80001f04 <sched>
  panic("zombie exit");
    800023e2:	00006517          	auipc	a0,0x6
    800023e6:	e8e50513          	addi	a0,a0,-370 # 80008270 <digits+0x230>
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	154080e7          	jalr	340(ra) # 8000053e <panic>

00000000800023f2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023f2:	7179                	addi	sp,sp,-48
    800023f4:	f406                	sd	ra,40(sp)
    800023f6:	f022                	sd	s0,32(sp)
    800023f8:	ec26                	sd	s1,24(sp)
    800023fa:	e84a                	sd	s2,16(sp)
    800023fc:	e44e                	sd	s3,8(sp)
    800023fe:	1800                	addi	s0,sp,48
    80002400:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002402:	0000f497          	auipc	s1,0xf
    80002406:	2ee48493          	addi	s1,s1,750 # 800116f0 <proc>
    8000240a:	00015997          	auipc	s3,0x15
    8000240e:	4e698993          	addi	s3,s3,1254 # 800178f0 <tickslock>
    acquire(&p->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	ffffe097          	auipc	ra,0xffffe
    80002418:	7d0080e7          	jalr	2000(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    8000241c:	589c                	lw	a5,48(s1)
    8000241e:	01278d63          	beq	a5,s2,80002438 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	874080e7          	jalr	-1932(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000242c:	18848493          	addi	s1,s1,392
    80002430:	ff3491e3          	bne	s1,s3,80002412 <kill+0x20>
  }
  return -1;
    80002434:	557d                	li	a0,-1
    80002436:	a829                	j	80002450 <kill+0x5e>
      p->killed = 1;
    80002438:	4785                	li	a5,1
    8000243a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000243c:	4c98                	lw	a4,24(s1)
    8000243e:	4789                	li	a5,2
    80002440:	00f70f63          	beq	a4,a5,8000245e <kill+0x6c>
      release(&p->lock);
    80002444:	8526                	mv	a0,s1
    80002446:	fffff097          	auipc	ra,0xfffff
    8000244a:	852080e7          	jalr	-1966(ra) # 80000c98 <release>
      return 0;
    8000244e:	4501                	li	a0,0
}
    80002450:	70a2                	ld	ra,40(sp)
    80002452:	7402                	ld	s0,32(sp)
    80002454:	64e2                	ld	s1,24(sp)
    80002456:	6942                	ld	s2,16(sp)
    80002458:	69a2                	ld	s3,8(sp)
    8000245a:	6145                	addi	sp,sp,48
    8000245c:	8082                	ret
        p->state = RUNNABLE;
    8000245e:	478d                	li	a5,3
    80002460:	cc9c                	sw	a5,24(s1)
    80002462:	b7cd                	j	80002444 <kill+0x52>

0000000080002464 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002464:	7179                	addi	sp,sp,-48
    80002466:	f406                	sd	ra,40(sp)
    80002468:	f022                	sd	s0,32(sp)
    8000246a:	ec26                	sd	s1,24(sp)
    8000246c:	e84a                	sd	s2,16(sp)
    8000246e:	e44e                	sd	s3,8(sp)
    80002470:	e052                	sd	s4,0(sp)
    80002472:	1800                	addi	s0,sp,48
    80002474:	84aa                	mv	s1,a0
    80002476:	892e                	mv	s2,a1
    80002478:	89b2                	mv	s3,a2
    8000247a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	534080e7          	jalr	1332(ra) # 800019b0 <myproc>
  if(user_dst){
    80002484:	c08d                	beqz	s1,800024a6 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002486:	86d2                	mv	a3,s4
    80002488:	864e                	mv	a2,s3
    8000248a:	85ca                	mv	a1,s2
    8000248c:	7928                	ld	a0,112(a0)
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	1e4080e7          	jalr	484(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002496:	70a2                	ld	ra,40(sp)
    80002498:	7402                	ld	s0,32(sp)
    8000249a:	64e2                	ld	s1,24(sp)
    8000249c:	6942                	ld	s2,16(sp)
    8000249e:	69a2                	ld	s3,8(sp)
    800024a0:	6a02                	ld	s4,0(sp)
    800024a2:	6145                	addi	sp,sp,48
    800024a4:	8082                	ret
    memmove((char *)dst, src, len);
    800024a6:	000a061b          	sext.w	a2,s4
    800024aa:	85ce                	mv	a1,s3
    800024ac:	854a                	mv	a0,s2
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	892080e7          	jalr	-1902(ra) # 80000d40 <memmove>
    return 0;
    800024b6:	8526                	mv	a0,s1
    800024b8:	bff9                	j	80002496 <either_copyout+0x32>

00000000800024ba <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ba:	7179                	addi	sp,sp,-48
    800024bc:	f406                	sd	ra,40(sp)
    800024be:	f022                	sd	s0,32(sp)
    800024c0:	ec26                	sd	s1,24(sp)
    800024c2:	e84a                	sd	s2,16(sp)
    800024c4:	e44e                	sd	s3,8(sp)
    800024c6:	e052                	sd	s4,0(sp)
    800024c8:	1800                	addi	s0,sp,48
    800024ca:	892a                	mv	s2,a0
    800024cc:	84ae                	mv	s1,a1
    800024ce:	89b2                	mv	s3,a2
    800024d0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	4de080e7          	jalr	1246(ra) # 800019b0 <myproc>
  if(user_src){
    800024da:	c08d                	beqz	s1,800024fc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024dc:	86d2                	mv	a3,s4
    800024de:	864e                	mv	a2,s3
    800024e0:	85ca                	mv	a1,s2
    800024e2:	7928                	ld	a0,112(a0)
    800024e4:	fffff097          	auipc	ra,0xfffff
    800024e8:	21a080e7          	jalr	538(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ec:	70a2                	ld	ra,40(sp)
    800024ee:	7402                	ld	s0,32(sp)
    800024f0:	64e2                	ld	s1,24(sp)
    800024f2:	6942                	ld	s2,16(sp)
    800024f4:	69a2                	ld	s3,8(sp)
    800024f6:	6a02                	ld	s4,0(sp)
    800024f8:	6145                	addi	sp,sp,48
    800024fa:	8082                	ret
    memmove(dst, (char*)src, len);
    800024fc:	000a061b          	sext.w	a2,s4
    80002500:	85ce                	mv	a1,s3
    80002502:	854a                	mv	a0,s2
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	83c080e7          	jalr	-1988(ra) # 80000d40 <memmove>
    return 0;
    8000250c:	8526                	mv	a0,s1
    8000250e:	bff9                	j	800024ec <either_copyin+0x32>

0000000080002510 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002510:	715d                	addi	sp,sp,-80
    80002512:	e486                	sd	ra,72(sp)
    80002514:	e0a2                	sd	s0,64(sp)
    80002516:	fc26                	sd	s1,56(sp)
    80002518:	f84a                	sd	s2,48(sp)
    8000251a:	f44e                	sd	s3,40(sp)
    8000251c:	f052                	sd	s4,32(sp)
    8000251e:	ec56                	sd	s5,24(sp)
    80002520:	e85a                	sd	s6,16(sp)
    80002522:	e45e                	sd	s7,8(sp)
    80002524:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002526:	00006517          	auipc	a0,0x6
    8000252a:	e7a50513          	addi	a0,a0,-390 # 800083a0 <digits+0x360>
    8000252e:	ffffe097          	auipc	ra,0xffffe
    80002532:	05a080e7          	jalr	90(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002536:	0000f497          	auipc	s1,0xf
    8000253a:	33248493          	addi	s1,s1,818 # 80011868 <proc+0x178>
    8000253e:	00015917          	auipc	s2,0x15
    80002542:	52a90913          	addi	s2,s2,1322 # 80017a68 <bcache+0x160>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002546:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002548:	00006997          	auipc	s3,0x6
    8000254c:	d3898993          	addi	s3,s3,-712 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002550:	00006a97          	auipc	s5,0x6
    80002554:	d38a8a93          	addi	s5,s5,-712 # 80008288 <digits+0x248>
    printf("\n");
    80002558:	00006a17          	auipc	s4,0x6
    8000255c:	e48a0a13          	addi	s4,s4,-440 # 800083a0 <digits+0x360>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002560:	00006b97          	auipc	s7,0x6
    80002564:	e70b8b93          	addi	s7,s7,-400 # 800083d0 <states.1735>
    80002568:	a00d                	j	8000258a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000256a:	eb86a583          	lw	a1,-328(a3)
    8000256e:	8556                	mv	a0,s5
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	018080e7          	jalr	24(ra) # 80000588 <printf>
    printf("\n");
    80002578:	8552                	mv	a0,s4
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	00e080e7          	jalr	14(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002582:	18848493          	addi	s1,s1,392
    80002586:	03248163          	beq	s1,s2,800025a8 <procdump+0x98>
    if(p->state == UNUSED)
    8000258a:	86a6                	mv	a3,s1
    8000258c:	ea04a783          	lw	a5,-352(s1)
    80002590:	dbed                	beqz	a5,80002582 <procdump+0x72>
      state = "???";
    80002592:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002594:	fcfb6be3          	bltu	s6,a5,8000256a <procdump+0x5a>
    80002598:	1782                	slli	a5,a5,0x20
    8000259a:	9381                	srli	a5,a5,0x20
    8000259c:	078e                	slli	a5,a5,0x3
    8000259e:	97de                	add	a5,a5,s7
    800025a0:	6390                	ld	a2,0(a5)
    800025a2:	f661                	bnez	a2,8000256a <procdump+0x5a>
      state = "???";
    800025a4:	864e                	mv	a2,s3
    800025a6:	b7d1                	j	8000256a <procdump+0x5a>
  }
}
    800025a8:	60a6                	ld	ra,72(sp)
    800025aa:	6406                	ld	s0,64(sp)
    800025ac:	74e2                	ld	s1,56(sp)
    800025ae:	7942                	ld	s2,48(sp)
    800025b0:	79a2                	ld	s3,40(sp)
    800025b2:	7a02                	ld	s4,32(sp)
    800025b4:	6ae2                	ld	s5,24(sp)
    800025b6:	6b42                	ld	s6,16(sp)
    800025b8:	6ba2                	ld	s7,8(sp)
    800025ba:	6161                	addi	sp,sp,80
    800025bc:	8082                	ret

00000000800025be <scheduler_round>:
//round robin scheduler.
//the default one in xv6
void
scheduler_round(void)
{
    800025be:	711d                	addi	sp,sp,-96
    800025c0:	ec86                	sd	ra,88(sp)
    800025c2:	e8a2                	sd	s0,80(sp)
    800025c4:	e4a6                	sd	s1,72(sp)
    800025c6:	e0ca                	sd	s2,64(sp)
    800025c8:	fc4e                	sd	s3,56(sp)
    800025ca:	f852                	sd	s4,48(sp)
    800025cc:	f456                	sd	s5,40(sp)
    800025ce:	f05a                	sd	s6,32(sp)
    800025d0:	ec5e                	sd	s7,24(sp)
    800025d2:	e862                	sd	s8,16(sp)
    800025d4:	e466                	sd	s9,8(sp)
    800025d6:	e06a                	sd	s10,0(sp)
    800025d8:	1080                	addi	s0,sp,96
  printf("\nRound robin priority selected\n");
    800025da:	00006517          	auipc	a0,0x6
    800025de:	cbe50513          	addi	a0,a0,-834 # 80008298 <digits+0x258>
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	fa6080e7          	jalr	-90(ra) # 80000588 <printf>
    800025ea:	8792                	mv	a5,tp
  int id = r_tp();
    800025ec:	2781                	sext.w	a5,a5
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
    800025ee:	00779c93          	slli	s9,a5,0x7
    800025f2:	0000f717          	auipc	a4,0xf
    800025f6:	cce70713          	addi	a4,a4,-818 # 800112c0 <pid_lock>
    800025fa:	9766                	add	a4,a4,s9
    800025fc:	02073823          	sd	zero,48(a4)
        uint toAdd= finish - p->last_runnable_time; 
        p->runnable_time =  p->runnable_time + toAdd; 
        p->last_run_time = finish;
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);
    80002600:	0000f717          	auipc	a4,0xf
    80002604:	cf870713          	addi	a4,a4,-776 # 800112f8 <cpus+0x8>
    80002608:	9cba                	add	s9,s9,a4
        if(ticks-starttick< tickNum && pauseflag==1){
    8000260a:	00007a97          	auipc	s5,0x7
    8000260e:	a4ea8a93          	addi	s5,s5,-1458 # 80009058 <ticks>
    80002612:	00007c17          	auipc	s8,0x7
    80002616:	a36c0c13          	addi	s8,s8,-1482 # 80009048 <starttick>
        c->proc = p;
    8000261a:	079e                	slli	a5,a5,0x7
    8000261c:	0000fb17          	auipc	s6,0xf
    80002620:	ca4b0b13          	addi	s6,s6,-860 # 800112c0 <pid_lock>
    80002624:	9b3e                	add	s6,s6,a5
    80002626:	a079                	j	800026b4 <scheduler_round+0xf6>
        p->runnable_time =  p->runnable_time + toAdd; 
    80002628:	48fc                	lw	a5,84(s1)
    8000262a:	012787bb          	addw	a5,a5,s2
    8000262e:	40b8                	lw	a4,64(s1)
    80002630:	9f99                	subw	a5,a5,a4
    80002632:	c8fc                	sw	a5,84(s1)
        p->last_run_time = finish;
    80002634:	0524a223          	sw	s2,68(s1)
        p->state = RUNNING;
    80002638:	4791                	li	a5,4
    8000263a:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    8000263c:	029b3823          	sd	s1,48(s6)
        swtch(&c->context, &p->context);
    80002640:	08098593          	addi	a1,s3,128
    80002644:	8566                	mv	a0,s9
    80002646:	00000097          	auipc	ra,0x0
    8000264a:	508080e7          	jalr	1288(ra) # 80002b4e <swtch>

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        p->run_time= p->run_time+ (ticks- finish);
    8000264e:	000aa783          	lw	a5,0(s5)
    80002652:	412787bb          	subw	a5,a5,s2
    80002656:	0504a903          	lw	s2,80(s1)
    8000265a:	00f9093b          	addw	s2,s2,a5
    8000265e:	0524a823          	sw	s2,80(s1)
        c->proc = 0;
    80002662:	020b3823          	sd	zero,48(s6)
      }
      release(&p->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	630080e7          	jalr	1584(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002670:	18848493          	addi	s1,s1,392
    80002674:	05448063          	beq	s1,s4,800026b4 <scheduler_round+0xf6>
      acquire(&p->lock);
    80002678:	89a6                	mv	s3,s1
    8000267a:	8526                	mv	a0,s1
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	568080e7          	jalr	1384(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002684:	4c98                	lw	a4,24(s1)
    80002686:	478d                	li	a5,3
    80002688:	fcf71fe3          	bne	a4,a5,80002666 <scheduler_round+0xa8>
        if(ticks-starttick< tickNum && pauseflag==1){
    8000268c:	000aa903          	lw	s2,0(s5)
    80002690:	000c2783          	lw	a5,0(s8)
    80002694:	40f907bb          	subw	a5,s2,a5
    80002698:	000ba703          	lw	a4,0(s7)
    8000269c:	f8e7f6e3          	bgeu	a5,a4,80002628 <scheduler_round+0x6a>
    800026a0:	000d2703          	lw	a4,0(s10)
    800026a4:	4785                	li	a5,1
    800026a6:	f8f711e3          	bne	a4,a5,80002628 <scheduler_round+0x6a>
          release(&p->lock);
    800026aa:	8526                	mv	a0,s1
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	5ec080e7          	jalr	1516(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800026b8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026bc:	10079073          	csrw	sstatus,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800026c0:	0000f497          	auipc	s1,0xf
    800026c4:	03048493          	addi	s1,s1,48 # 800116f0 <proc>
        if(ticks-starttick< tickNum && pauseflag==1){
    800026c8:	00007b97          	auipc	s7,0x7
    800026cc:	984b8b93          	addi	s7,s7,-1660 # 8000904c <tickNum>
    800026d0:	00007d17          	auipc	s10,0x7
    800026d4:	974d0d13          	addi	s10,s10,-1676 # 80009044 <pauseflag>
    for(p = proc; p < &proc[NPROC]; p++) {
    800026d8:	00015a17          	auipc	s4,0x15
    800026dc:	218a0a13          	addi	s4,s4,536 # 800178f0 <tickslock>
    800026e0:	bf61                	j	80002678 <scheduler_round+0xba>

00000000800026e2 <scheduler_sjf>:
}


//Approximate SJF policy .
void
scheduler_sjf(void){
    800026e2:	7119                	addi	sp,sp,-128
    800026e4:	fc86                	sd	ra,120(sp)
    800026e6:	f8a2                	sd	s0,112(sp)
    800026e8:	f4a6                	sd	s1,104(sp)
    800026ea:	f0ca                	sd	s2,96(sp)
    800026ec:	ecce                	sd	s3,88(sp)
    800026ee:	e8d2                	sd	s4,80(sp)
    800026f0:	e4d6                	sd	s5,72(sp)
    800026f2:	e0da                	sd	s6,64(sp)
    800026f4:	fc5e                	sd	s7,56(sp)
    800026f6:	f862                	sd	s8,48(sp)
    800026f8:	f466                	sd	s9,40(sp)
    800026fa:	f06a                	sd	s10,32(sp)
    800026fc:	ec6e                	sd	s11,24(sp)
    800026fe:	0100                	addi	s0,sp,128

  printf("\nSJF priority selected\n");
    80002700:	00006517          	auipc	a0,0x6
    80002704:	bb850513          	addi	a0,a0,-1096 # 800082b8 <digits+0x278>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	e80080e7          	jalr	-384(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002710:	8792                	mv	a5,tp
  int id = r_tp();
    80002712:	2781                	sext.w	a5,a5
  struct proc *p;
  struct cpu *c = mycpu();
  struct proc *cp = 0;
  //store the min mean ticks value.
  int mmt= __INT_MAX__;
  c->proc = 0 ;
    80002714:	00779693          	slli	a3,a5,0x7
    80002718:	0000f717          	auipc	a4,0xf
    8000271c:	ba870713          	addi	a4,a4,-1112 # 800112c0 <pid_lock>
    80002720:	9736                	add	a4,a4,a3
    80002722:	02073823          	sd	zero,48(a4)
        cp->last_runnable_time =finished;
        uint tot_runnable= finished - cp->last_runnable_time;
        cp-> runnable_time = cp-> runnable_time+tot_runnable;
        c->proc=cp;
        cp->ticks_start= finished;
        swtch(&c->context, &p->context);
    80002726:	0000f717          	auipc	a4,0xf
    8000272a:	bd270713          	addi	a4,a4,-1070 # 800112f8 <cpus+0x8>
    8000272e:	9736                	add	a4,a4,a3
    80002730:	f8e43423          	sd	a4,-120(s0)
  int mmt= __INT_MAX__;
    80002734:	80000cb7          	lui	s9,0x80000
    80002738:	fffccc93          	not	s9,s9
  struct proc *cp = 0;
    8000273c:	4d01                	li	s10,0
      if(ticks-starttick< tickNum && pauseflag==1){
    8000273e:	00007a17          	auipc	s4,0x7
    80002742:	91aa0a13          	addi	s4,s4,-1766 # 80009058 <ticks>
    80002746:	00007c17          	auipc	s8,0x7
    8000274a:	8fec0c13          	addi	s8,s8,-1794 # 80009044 <pauseflag>
    for( p= proc ; p < &proc[NPROC] ; p++){
    8000274e:	00015b17          	auipc	s6,0x15
    80002752:	1a2b0b13          	addi	s6,s6,418 # 800178f0 <tickslock>
        c->proc=cp;
    80002756:	0000fd97          	auipc	s11,0xf
    8000275a:	b6ad8d93          	addi	s11,s11,-1174 # 800112c0 <pid_lock>
    8000275e:	9db6                	add	s11,s11,a3
    80002760:	a8c1                	j	80002830 <scheduler_sjf+0x14e>
      else if(p->state == RUNNABLE && (p->mean_ticks < mmt)){
    80002762:	4c9c                	lw	a5,24(s1)
    80002764:	0f578b63          	beq	a5,s5,8000285a <scheduler_sjf+0x178>
      release(&p->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	52e080e7          	jalr	1326(ra) # 80000c98 <release>
    for( p= proc ; p < &proc[NPROC] ; p++){
    80002772:	18848493          	addi	s1,s1,392
    80002776:	03648963          	beq	s1,s6,800027a8 <scheduler_sjf+0xc6>
      acquire(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	468080e7          	jalr	1128(ra) # 80000be4 <acquire>
      if(ticks-starttick< tickNum && pauseflag==1){
    80002784:	000a2783          	lw	a5,0(s4)
    80002788:	0009a703          	lw	a4,0(s3)
    8000278c:	9f99                	subw	a5,a5,a4
    8000278e:	00092703          	lw	a4,0(s2)
    80002792:	fce7f8e3          	bgeu	a5,a4,80002762 <scheduler_sjf+0x80>
    80002796:	000c2783          	lw	a5,0(s8)
    8000279a:	fd7794e3          	bne	a5,s7,80002762 <scheduler_sjf+0x80>
         release(&p->lock);
    8000279e:	8526                	mv	a0,s1
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	4f8080e7          	jalr	1272(ra) # 80000c98 <release>
    if(cp !=0){
    800027a8:	080d0463          	beqz	s10,80002830 <scheduler_sjf+0x14e>
      acquire(&cp->lock);
    800027ac:	896a                	mv	s2,s10
    800027ae:	856a                	mv	a0,s10
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	434080e7          	jalr	1076(ra) # 80000be4 <acquire>
      if(cp->state==RUNNABLE){
    800027b8:	018d2703          	lw	a4,24(s10)
    800027bc:	478d                	li	a5,3
    800027be:	06f71463          	bne	a4,a5,80002826 <scheduler_sjf+0x144>
        uint finished = ticks;
    800027c2:	000a2983          	lw	s3,0(s4)
        cp->state=RUNNING;
    800027c6:	4791                	li	a5,4
    800027c8:	00fd2c23          	sw	a5,24(s10)
        cp->last_runnable_time =finished;
    800027cc:	053d2023          	sw	s3,64(s10)
        c->proc=cp;
    800027d0:	03adb823          	sd	s10,48(s11)
        cp->ticks_start= finished;
    800027d4:	033d2e23          	sw	s3,60(s10)
        swtch(&c->context, &p->context);
    800027d8:	08048593          	addi	a1,s1,128
    800027dc:	f8843503          	ld	a0,-120(s0)
    800027e0:	00000097          	auipc	ra,0x0
    800027e4:	36e080e7          	jalr	878(ra) # 80002b4e <swtch>

        // Process is done running for now.
        // It should have changed its p->state before coming back.

        uint runn= ticks - finished;
    800027e8:	000a2703          	lw	a4,0(s4)
    800027ec:	4137073b          	subw	a4,a4,s3
        cp->run_time = cp->run_time + runn;
    800027f0:	050d2783          	lw	a5,80(s10)
    800027f4:	9fb9                	addw	a5,a5,a4
    800027f6:	04fd2823          	sw	a5,80(s10)
        cp->last_ticks= ticks - finished;
    800027fa:	02ed2c23          	sw	a4,56(s10)
        cp->mean_ticks = ((10-rate)*cp->mean_ticks + cp->last_ticks*rate)/10;
    800027fe:	00006617          	auipc	a2,0x6
    80002802:	14662603          	lw	a2,326(a2) # 80008944 <rate>
    80002806:	46a9                	li	a3,10
    80002808:	40c687bb          	subw	a5,a3,a2
    8000280c:	034d2583          	lw	a1,52(s10)
    80002810:	02b787bb          	mulw	a5,a5,a1
    80002814:	02c7073b          	mulw	a4,a4,a2
    80002818:	9fb9                	addw	a5,a5,a4
    8000281a:	02d7c7bb          	divw	a5,a5,a3
    8000281e:	02fd2a23          	sw	a5,52(s10)
        c->proc=0;
    80002822:	020db823          	sd	zero,48(s11)
      }
      release(&cp->lock);
    80002826:	854a                	mv	a0,s2
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	470080e7          	jalr	1136(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002830:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002834:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002838:	10079073          	csrw	sstatus,a5
    for( p= proc ; p < &proc[NPROC] ; p++){
    8000283c:	0000f497          	auipc	s1,0xf
    80002840:	eb448493          	addi	s1,s1,-332 # 800116f0 <proc>
      if(ticks-starttick< tickNum && pauseflag==1){
    80002844:	00007997          	auipc	s3,0x7
    80002848:	80498993          	addi	s3,s3,-2044 # 80009048 <starttick>
    8000284c:	00007917          	auipc	s2,0x7
    80002850:	80090913          	addi	s2,s2,-2048 # 8000904c <tickNum>
    80002854:	4b85                	li	s7,1
      else if(p->state == RUNNABLE && (p->mean_ticks < mmt)){
    80002856:	4a8d                	li	s5,3
    80002858:	b70d                	j	8000277a <scheduler_sjf+0x98>
    8000285a:	58dc                	lw	a5,52(s1)
    8000285c:	f197d6e3          	bge	a5,s9,80002768 <scheduler_sjf+0x86>
        mmt= p->mean_ticks;
    80002860:	8cbe                	mv	s9,a5
      else if(p->state == RUNNABLE && (p->mean_ticks < mmt)){
    80002862:	8d26                	mv	s10,s1
    80002864:	b711                	j	80002768 <scheduler_sjf+0x86>

0000000080002866 <scheduler_fcfs>:



//First come first served policy .
void
scheduler_fcfs(void){
    80002866:	7159                	addi	sp,sp,-112
    80002868:	f486                	sd	ra,104(sp)
    8000286a:	f0a2                	sd	s0,96(sp)
    8000286c:	eca6                	sd	s1,88(sp)
    8000286e:	e8ca                	sd	s2,80(sp)
    80002870:	e4ce                	sd	s3,72(sp)
    80002872:	e0d2                	sd	s4,64(sp)
    80002874:	fc56                	sd	s5,56(sp)
    80002876:	f85a                	sd	s6,48(sp)
    80002878:	f45e                	sd	s7,40(sp)
    8000287a:	f062                	sd	s8,32(sp)
    8000287c:	ec66                	sd	s9,24(sp)
    8000287e:	e86a                	sd	s10,16(sp)
    80002880:	e46e                	sd	s11,8(sp)
    80002882:	1880                	addi	s0,sp,112

   printf("\nFCFS priority selected\n");
    80002884:	00006517          	auipc	a0,0x6
    80002888:	a4c50513          	addi	a0,a0,-1460 # 800082d0 <digits+0x290>
    8000288c:	ffffe097          	auipc	ra,0xffffe
    80002890:	cfc080e7          	jalr	-772(ra) # 80000588 <printf>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002894:	8492                	mv	s1,tp
  int id = r_tp();
    80002896:	2481                	sext.w	s1,s1
  struct proc *p;
  struct cpu *c = mycpu();
  struct proc *cp = myproc();
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	118080e7          	jalr	280(ra) # 800019b0 <myproc>
    800028a0:	8baa                	mv	s7,a0
  c->proc = 0 ;
    800028a2:	00749d93          	slli	s11,s1,0x7
    800028a6:	0000f797          	auipc	a5,0xf
    800028aa:	a1a78793          	addi	a5,a5,-1510 # 800112c0 <pid_lock>
    800028ae:	97ee                	add	a5,a5,s11
    800028b0:	0207b823          	sd	zero,48(a5)
        uint addRun = endRun - p->last_runnable_time;
        cp->runnable_time = cp->runnable_time + addRun;
        cp->state=RUNNING;
        cp->last_run_time=endRun;
        c->proc=cp;
        swtch(&c->context, &p->context);
    800028b4:	0000f797          	auipc	a5,0xf
    800028b8:	a4478793          	addi	a5,a5,-1468 # 800112f8 <cpus+0x8>
    800028bc:	9dbe                	add	s11,s11,a5
      if(ticks-starttick< tickNum && pauseflag==1){
    800028be:	00006a17          	auipc	s4,0x6
    800028c2:	79aa0a13          	addi	s4,s4,1946 # 80009058 <ticks>
    800028c6:	00006c97          	auipc	s9,0x6
    800028ca:	77ec8c93          	addi	s9,s9,1918 # 80009044 <pauseflag>
    for( p= proc ; p < &proc[NPROC] ; p++){
    800028ce:	00015b17          	auipc	s6,0x15
    800028d2:	022b0b13          	addi	s6,s6,34 # 800178f0 <tickslock>
        c->proc=cp;
    800028d6:	049e                	slli	s1,s1,0x7
    800028d8:	0000fd17          	auipc	s10,0xf
    800028dc:	9e8d0d13          	addi	s10,s10,-1560 # 800112c0 <pid_lock>
    800028e0:	9d26                	add	s10,s10,s1
    800028e2:	a855                	j	80002996 <scheduler_fcfs+0x130>
      else if(p->state == RUNNABLE && (p->last_runnable_time < cp->last_runnable_time)){
    800028e4:	4c9c                	lw	a5,24(s1)
    800028e6:	0d578d63          	beq	a5,s5,800029c0 <scheduler_fcfs+0x15a>
      release(&p->lock);
    800028ea:	8526                	mv	a0,s1
    800028ec:	ffffe097          	auipc	ra,0xffffe
    800028f0:	3ac080e7          	jalr	940(ra) # 80000c98 <release>
    for( p= proc ; p < &proc[NPROC] ; p++){
    800028f4:	18848493          	addi	s1,s1,392
    800028f8:	03648963          	beq	s1,s6,8000292a <scheduler_fcfs+0xc4>
      acquire(&p->lock);
    800028fc:	8526                	mv	a0,s1
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	2e6080e7          	jalr	742(ra) # 80000be4 <acquire>
      if(ticks-starttick< tickNum && pauseflag==1){
    80002906:	000a2783          	lw	a5,0(s4)
    8000290a:	0009a703          	lw	a4,0(s3)
    8000290e:	9f99                	subw	a5,a5,a4
    80002910:	00092703          	lw	a4,0(s2)
    80002914:	fce7f8e3          	bgeu	a5,a4,800028e4 <scheduler_fcfs+0x7e>
    80002918:	000ca783          	lw	a5,0(s9)
    8000291c:	fd8794e3          	bne	a5,s8,800028e4 <scheduler_fcfs+0x7e>
         release(&p->lock);
    80002920:	8526                	mv	a0,s1
    80002922:	ffffe097          	auipc	ra,0xffffe
    80002926:	376080e7          	jalr	886(ra) # 80000c98 <release>
    if(cp !=0){
    8000292a:	060b8663          	beqz	s7,80002996 <scheduler_fcfs+0x130>
      acquire(&cp->lock);
    8000292e:	89de                	mv	s3,s7
    80002930:	855e                	mv	a0,s7
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	2b2080e7          	jalr	690(ra) # 80000be4 <acquire>
      if(cp->state==RUNNABLE){
    8000293a:	018ba703          	lw	a4,24(s7)
    8000293e:	478d                	li	a5,3
    80002940:	04f71663          	bne	a4,a5,8000298c <scheduler_fcfs+0x126>
        uint endRun = ticks;
    80002944:	000a2903          	lw	s2,0(s4)
        cp->runnable_time = cp->runnable_time + addRun;
    80002948:	054ba783          	lw	a5,84(s7)
    8000294c:	012787bb          	addw	a5,a5,s2
    80002950:	40b8                	lw	a4,64(s1)
    80002952:	9f99                	subw	a5,a5,a4
    80002954:	04fbaa23          	sw	a5,84(s7)
        cp->state=RUNNING;
    80002958:	4791                	li	a5,4
    8000295a:	00fbac23          	sw	a5,24(s7)
        cp->last_run_time=endRun;
    8000295e:	052ba223          	sw	s2,68(s7)
        c->proc=cp;
    80002962:	037d3823          	sd	s7,48(s10)
        swtch(&c->context, &p->context);
    80002966:	08048593          	addi	a1,s1,128
    8000296a:	856e                	mv	a0,s11
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	1e2080e7          	jalr	482(ra) # 80002b4e <swtch>

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        uint currRun= ticks- endRun;
    80002974:	000a2783          	lw	a5,0(s4)
    80002978:	4127893b          	subw	s2,a5,s2
        cp->run_time= cp->run_time + currRun;
    8000297c:	050ba783          	lw	a5,80(s7)
    80002980:	012787bb          	addw	a5,a5,s2
    80002984:	04fba823          	sw	a5,80(s7)
        c->proc=0;
    80002988:	020d3823          	sd	zero,48(s10)
      }
      release(&cp->lock);
    8000298c:	854e                	mv	a0,s3
    8000298e:	ffffe097          	auipc	ra,0xffffe
    80002992:	30a080e7          	jalr	778(ra) # 80000c98 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000299a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299e:	10079073          	csrw	sstatus,a5
    for( p= proc ; p < &proc[NPROC] ; p++){
    800029a2:	0000f497          	auipc	s1,0xf
    800029a6:	d4e48493          	addi	s1,s1,-690 # 800116f0 <proc>
      if(ticks-starttick< tickNum && pauseflag==1){
    800029aa:	00006997          	auipc	s3,0x6
    800029ae:	69e98993          	addi	s3,s3,1694 # 80009048 <starttick>
    800029b2:	00006917          	auipc	s2,0x6
    800029b6:	69a90913          	addi	s2,s2,1690 # 8000904c <tickNum>
    800029ba:	4c05                	li	s8,1
      else if(p->state == RUNNABLE && (p->last_runnable_time < cp->last_runnable_time)){
    800029bc:	4a8d                	li	s5,3
    800029be:	bf3d                	j	800028fc <scheduler_fcfs+0x96>
    800029c0:	40b8                	lw	a4,64(s1)
    800029c2:	040ba783          	lw	a5,64(s7)
    800029c6:	f2f772e3          	bgeu	a4,a5,800028ea <scheduler_fcfs+0x84>
    800029ca:	8ba6                	mv	s7,s1
    800029cc:	bf39                	j	800028ea <scheduler_fcfs+0x84>

00000000800029ce <scheduler>:
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void)
{
    800029ce:	1141                	addi	sp,sp,-16
    800029d0:	e406                	sd	ra,8(sp)
    800029d2:	e022                	sd	s0,0(sp)
    800029d4:	0800                	addi	s0,sp,16
  #elif SJF
    scheduler_sjf();
  #elif RR
    scheduler_sjf();
  #elif DEFAULT
    scheduler_round();
    800029d6:	00000097          	auipc	ra,0x0
    800029da:	be8080e7          	jalr	-1048(ra) # 800025be <scheduler_round>

00000000800029de <pause_system>:



//pause all cpu processes
int
pause_system(int sec){
    800029de:	1101                	addi	sp,sp,-32
    800029e0:	ec06                	sd	ra,24(sp)
    800029e2:	e822                	sd	s0,16(sp)
    800029e4:	e426                	sd	s1,8(sp)
    800029e6:	1000                	addi	s0,sp,32
  
  tickNum= 1000000 *sec;
    800029e8:	000f47b7          	lui	a5,0xf4
    800029ec:	2407879b          	addiw	a5,a5,576
    800029f0:	02a787bb          	mulw	a5,a5,a0
    800029f4:	00006717          	auipc	a4,0x6
    800029f8:	64f72c23          	sw	a5,1624(a4) # 8000904c <tickNum>
  starttick = ticks;
    800029fc:	00006797          	auipc	a5,0x6
    80002a00:	65c7a783          	lw	a5,1628(a5) # 80009058 <ticks>
    80002a04:	00006717          	auipc	a4,0x6
    80002a08:	64f72223          	sw	a5,1604(a4) # 80009048 <starttick>
  pauseflag = 1;
    80002a0c:	00006497          	auipc	s1,0x6
    80002a10:	63848493          	addi	s1,s1,1592 # 80009044 <pauseflag>
    80002a14:	4785                	li	a5,1
    80002a16:	c09c                	sw	a5,0(s1)
  yield();
    80002a18:	fffff097          	auipc	ra,0xfffff
    80002a1c:	5c2080e7          	jalr	1474(ra) # 80001fda <yield>
  pauseflag = 0;
    80002a20:	0004a023          	sw	zero,0(s1)
  return 0;
}
    80002a24:	4501                	li	a0,0
    80002a26:	60e2                	ld	ra,24(sp)
    80002a28:	6442                	ld	s0,16(sp)
    80002a2a:	64a2                	ld	s1,8(sp)
    80002a2c:	6105                	addi	sp,sp,32
    80002a2e:	8082                	ret

0000000080002a30 <kill_system>:

//kill all procs except init and shell
int
kill_system(void){
    80002a30:	715d                	addi	sp,sp,-80
    80002a32:	e486                	sd	ra,72(sp)
    80002a34:	e0a2                	sd	s0,64(sp)
    80002a36:	fc26                	sd	s1,56(sp)
    80002a38:	f84a                	sd	s2,48(sp)
    80002a3a:	f44e                	sd	s3,40(sp)
    80002a3c:	f052                	sd	s4,32(sp)
    80002a3e:	ec56                	sd	s5,24(sp)
    80002a40:	e85a                	sd	s6,16(sp)
    80002a42:	e45e                	sd	s7,8(sp)
    80002a44:	0880                	addi	s0,sp,80
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++){
    80002a46:	0000f497          	auipc	s1,0xf
    80002a4a:	caa48493          	addi	s1,s1,-854 # 800116f0 <proc>
    acquire(&p->lock);
    if(p->pid !=1  && p->pid !=2){
    80002a4e:	4985                	li	s3,1
      p->killed = 1;
    80002a50:	4a85                	li	s5,1
      if(p->state == SLEEPING){
    80002a52:	4a09                	li	s4,2
        // Wake process from sleep().
        uint sleep_stop= ticks;
    80002a54:	00006b97          	auipc	s7,0x6
    80002a58:	604b8b93          	addi	s7,s7,1540 # 80009058 <ticks>
        p->state = RUNNABLE;
    80002a5c:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++){
    80002a5e:	00015917          	auipc	s2,0x15
    80002a62:	e9290913          	addi	s2,s2,-366 # 800178f0 <tickslock>
    80002a66:	a811                	j	80002a7a <kill_system+0x4a>
        uint sleep_add= sleep_stop- p->last_sleep_time;
        p->sleep_time= p->sleep_time + sleep_add;
        p->last_runnable_time=ticks;
      }
    }
    release(&p->lock);
    80002a68:	8526                	mv	a0,s1
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	22e080e7          	jalr	558(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a72:	18848493          	addi	s1,s1,392
    80002a76:	03248b63          	beq	s1,s2,80002aac <kill_system+0x7c>
    acquire(&p->lock);
    80002a7a:	8526                	mv	a0,s1
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	168080e7          	jalr	360(ra) # 80000be4 <acquire>
    if(p->pid !=1  && p->pid !=2){
    80002a84:	589c                	lw	a5,48(s1)
    80002a86:	37fd                	addiw	a5,a5,-1
    80002a88:	fef9f0e3          	bgeu	s3,a5,80002a68 <kill_system+0x38>
      p->killed = 1;
    80002a8c:	0354a423          	sw	s5,40(s1)
      if(p->state == SLEEPING){
    80002a90:	4c9c                	lw	a5,24(s1)
    80002a92:	fd479be3          	bne	a5,s4,80002a68 <kill_system+0x38>
        uint sleep_stop= ticks;
    80002a96:	000ba703          	lw	a4,0(s7)
        p->state = RUNNABLE;
    80002a9a:	0164ac23          	sw	s6,24(s1)
        p->sleep_time= p->sleep_time + sleep_add;
    80002a9e:	44fc                	lw	a5,76(s1)
    80002aa0:	9fb9                	addw	a5,a5,a4
    80002aa2:	44b4                	lw	a3,72(s1)
    80002aa4:	9f95                	subw	a5,a5,a3
    80002aa6:	c4fc                	sw	a5,76(s1)
        p->last_runnable_time=ticks;
    80002aa8:	c0b8                	sw	a4,64(s1)
    80002aaa:	bf7d                	j	80002a68 <kill_system+0x38>
  }
  return -1;
}
    80002aac:	557d                	li	a0,-1
    80002aae:	60a6                	ld	ra,72(sp)
    80002ab0:	6406                	ld	s0,64(sp)
    80002ab2:	74e2                	ld	s1,56(sp)
    80002ab4:	7942                	ld	s2,48(sp)
    80002ab6:	79a2                	ld	s3,40(sp)
    80002ab8:	7a02                	ld	s4,32(sp)
    80002aba:	6ae2                	ld	s5,24(sp)
    80002abc:	6b42                	ld	s6,16(sp)
    80002abe:	6ba2                	ld	s7,8(sp)
    80002ac0:	6161                	addi	sp,sp,80
    80002ac2:	8082                	ret

0000000080002ac4 <print_sys_status>:


int print_sys_status(void) {
    80002ac4:	1141                	addi	sp,sp,-16
    80002ac6:	e406                	sd	ra,8(sp)
    80002ac8:	e022                	sd	s0,0(sp)
    80002aca:	0800                	addi	s0,sp,16
  printf("The running_processes_mean is : %d\n", running_processes_mean);
    80002acc:	00006597          	auipc	a1,0x6
    80002ad0:	5685a583          	lw	a1,1384(a1) # 80009034 <running_processes_mean>
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	81c50513          	addi	a0,a0,-2020 # 800082f0 <digits+0x2b0>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	aac080e7          	jalr	-1364(ra) # 80000588 <printf>
  printf("Therunnable_processes_mean is : %d\n", runnable_processes_mean);
    80002ae4:	00006597          	auipc	a1,0x6
    80002ae8:	5545a583          	lw	a1,1364(a1) # 80009038 <runnable_processes_mean>
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	82c50513          	addi	a0,a0,-2004 # 80008318 <digits+0x2d8>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a94080e7          	jalr	-1388(ra) # 80000588 <printf>
  printf("The sleeping_processes_mean is : %d\n", sleeping_processes_mean);
    80002afc:	00006597          	auipc	a1,0x6
    80002b00:	5405a583          	lw	a1,1344(a1) # 8000903c <sleeping_processes_mean>
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	83c50513          	addi	a0,a0,-1988 # 80008340 <digits+0x300>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a7c080e7          	jalr	-1412(ra) # 80000588 <printf>
  printf("The cpu utilization is : %d\n", cpuUse);
    80002b14:	00006597          	auipc	a1,0x6
    80002b18:	5145a583          	lw	a1,1300(a1) # 80009028 <cpuUse>
    80002b1c:	00006517          	auipc	a0,0x6
    80002b20:	84c50513          	addi	a0,a0,-1972 # 80008368 <digits+0x328>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a64080e7          	jalr	-1436(ra) # 80000588 <printf>
  printf("The program time is : %d\n", program_time);
    80002b2c:	00006597          	auipc	a1,0x6
    80002b30:	5005a583          	lw	a1,1280(a1) # 8000902c <program_time>
    80002b34:	00006517          	auipc	a0,0x6
    80002b38:	85450513          	addi	a0,a0,-1964 # 80008388 <digits+0x348>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	a4c080e7          	jalr	-1460(ra) # 80000588 <printf>
  return 0;
    80002b44:	4501                	li	a0,0
    80002b46:	60a2                	ld	ra,8(sp)
    80002b48:	6402                	ld	s0,0(sp)
    80002b4a:	0141                	addi	sp,sp,16
    80002b4c:	8082                	ret

0000000080002b4e <swtch>:
    80002b4e:	00153023          	sd	ra,0(a0)
    80002b52:	00253423          	sd	sp,8(a0)
    80002b56:	e900                	sd	s0,16(a0)
    80002b58:	ed04                	sd	s1,24(a0)
    80002b5a:	03253023          	sd	s2,32(a0)
    80002b5e:	03353423          	sd	s3,40(a0)
    80002b62:	03453823          	sd	s4,48(a0)
    80002b66:	03553c23          	sd	s5,56(a0)
    80002b6a:	05653023          	sd	s6,64(a0)
    80002b6e:	05753423          	sd	s7,72(a0)
    80002b72:	05853823          	sd	s8,80(a0)
    80002b76:	05953c23          	sd	s9,88(a0)
    80002b7a:	07a53023          	sd	s10,96(a0)
    80002b7e:	07b53423          	sd	s11,104(a0)
    80002b82:	0005b083          	ld	ra,0(a1)
    80002b86:	0085b103          	ld	sp,8(a1)
    80002b8a:	6980                	ld	s0,16(a1)
    80002b8c:	6d84                	ld	s1,24(a1)
    80002b8e:	0205b903          	ld	s2,32(a1)
    80002b92:	0285b983          	ld	s3,40(a1)
    80002b96:	0305ba03          	ld	s4,48(a1)
    80002b9a:	0385ba83          	ld	s5,56(a1)
    80002b9e:	0405bb03          	ld	s6,64(a1)
    80002ba2:	0485bb83          	ld	s7,72(a1)
    80002ba6:	0505bc03          	ld	s8,80(a1)
    80002baa:	0585bc83          	ld	s9,88(a1)
    80002bae:	0605bd03          	ld	s10,96(a1)
    80002bb2:	0685bd83          	ld	s11,104(a1)
    80002bb6:	8082                	ret

0000000080002bb8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bb8:	1141                	addi	sp,sp,-16
    80002bba:	e406                	sd	ra,8(sp)
    80002bbc:	e022                	sd	s0,0(sp)
    80002bbe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bc0:	00006597          	auipc	a1,0x6
    80002bc4:	84058593          	addi	a1,a1,-1984 # 80008400 <states.1735+0x30>
    80002bc8:	00015517          	auipc	a0,0x15
    80002bcc:	d2850513          	addi	a0,a0,-728 # 800178f0 <tickslock>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	f84080e7          	jalr	-124(ra) # 80000b54 <initlock>
}
    80002bd8:	60a2                	ld	ra,8(sp)
    80002bda:	6402                	ld	s0,0(sp)
    80002bdc:	0141                	addi	sp,sp,16
    80002bde:	8082                	ret

0000000080002be0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002be0:	1141                	addi	sp,sp,-16
    80002be2:	e422                	sd	s0,8(sp)
    80002be4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002be6:	00003797          	auipc	a5,0x3
    80002bea:	4ea78793          	addi	a5,a5,1258 # 800060d0 <kernelvec>
    80002bee:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bf2:	6422                	ld	s0,8(sp)
    80002bf4:	0141                	addi	sp,sp,16
    80002bf6:	8082                	ret

0000000080002bf8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bf8:	1141                	addi	sp,sp,-16
    80002bfa:	e406                	sd	ra,8(sp)
    80002bfc:	e022                	sd	s0,0(sp)
    80002bfe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c00:	fffff097          	auipc	ra,0xfffff
    80002c04:	db0080e7          	jalr	-592(ra) # 800019b0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c08:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c0c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c0e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002c12:	00004617          	auipc	a2,0x4
    80002c16:	3ee60613          	addi	a2,a2,1006 # 80007000 <_trampoline>
    80002c1a:	00004697          	auipc	a3,0x4
    80002c1e:	3e668693          	addi	a3,a3,998 # 80007000 <_trampoline>
    80002c22:	8e91                	sub	a3,a3,a2
    80002c24:	040007b7          	lui	a5,0x4000
    80002c28:	17fd                	addi	a5,a5,-1
    80002c2a:	07b2                	slli	a5,a5,0xc
    80002c2c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c2e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c32:	7d38                	ld	a4,120(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c34:	180026f3          	csrr	a3,satp
    80002c38:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c3a:	7d38                	ld	a4,120(a0)
    80002c3c:	7134                	ld	a3,96(a0)
    80002c3e:	6585                	lui	a1,0x1
    80002c40:	96ae                	add	a3,a3,a1
    80002c42:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c44:	7d38                	ld	a4,120(a0)
    80002c46:	00000697          	auipc	a3,0x0
    80002c4a:	13868693          	addi	a3,a3,312 # 80002d7e <usertrap>
    80002c4e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c50:	7d38                	ld	a4,120(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c52:	8692                	mv	a3,tp
    80002c54:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c56:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c5a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c5e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c62:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c66:	7d38                	ld	a4,120(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c68:	6f18                	ld	a4,24(a4)
    80002c6a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c6e:	792c                	ld	a1,112(a0)
    80002c70:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002c72:	00004717          	auipc	a4,0x4
    80002c76:	41e70713          	addi	a4,a4,1054 # 80007090 <userret>
    80002c7a:	8f11                	sub	a4,a4,a2
    80002c7c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002c7e:	577d                	li	a4,-1
    80002c80:	177e                	slli	a4,a4,0x3f
    80002c82:	8dd9                	or	a1,a1,a4
    80002c84:	02000537          	lui	a0,0x2000
    80002c88:	157d                	addi	a0,a0,-1
    80002c8a:	0536                	slli	a0,a0,0xd
    80002c8c:	9782                	jalr	a5
}
    80002c8e:	60a2                	ld	ra,8(sp)
    80002c90:	6402                	ld	s0,0(sp)
    80002c92:	0141                	addi	sp,sp,16
    80002c94:	8082                	ret

0000000080002c96 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	e426                	sd	s1,8(sp)
    80002c9e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ca0:	00015497          	auipc	s1,0x15
    80002ca4:	c5048493          	addi	s1,s1,-944 # 800178f0 <tickslock>
    80002ca8:	8526                	mv	a0,s1
    80002caa:	ffffe097          	auipc	ra,0xffffe
    80002cae:	f3a080e7          	jalr	-198(ra) # 80000be4 <acquire>
  ticks++;
    80002cb2:	00006517          	auipc	a0,0x6
    80002cb6:	3a650513          	addi	a0,a0,934 # 80009058 <ticks>
    80002cba:	411c                	lw	a5,0(a0)
    80002cbc:	2785                	addiw	a5,a5,1
    80002cbe:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cc0:	fffff097          	auipc	ra,0xfffff
    80002cc4:	4e2080e7          	jalr	1250(ra) # 800021a2 <wakeup>
  release(&tickslock);
    80002cc8:	8526                	mv	a0,s1
    80002cca:	ffffe097          	auipc	ra,0xffffe
    80002cce:	fce080e7          	jalr	-50(ra) # 80000c98 <release>
}
    80002cd2:	60e2                	ld	ra,24(sp)
    80002cd4:	6442                	ld	s0,16(sp)
    80002cd6:	64a2                	ld	s1,8(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002cdc:	1101                	addi	sp,sp,-32
    80002cde:	ec06                	sd	ra,24(sp)
    80002ce0:	e822                	sd	s0,16(sp)
    80002ce2:	e426                	sd	s1,8(sp)
    80002ce4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ce6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002cea:	00074d63          	bltz	a4,80002d04 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cee:	57fd                	li	a5,-1
    80002cf0:	17fe                	slli	a5,a5,0x3f
    80002cf2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cf4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cf6:	06f70363          	beq	a4,a5,80002d5c <devintr+0x80>
  }
}
    80002cfa:	60e2                	ld	ra,24(sp)
    80002cfc:	6442                	ld	s0,16(sp)
    80002cfe:	64a2                	ld	s1,8(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret
     (scause & 0xff) == 9){
    80002d04:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002d08:	46a5                	li	a3,9
    80002d0a:	fed792e3          	bne	a5,a3,80002cee <devintr+0x12>
    int irq = plic_claim();
    80002d0e:	00003097          	auipc	ra,0x3
    80002d12:	4ca080e7          	jalr	1226(ra) # 800061d8 <plic_claim>
    80002d16:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d18:	47a9                	li	a5,10
    80002d1a:	02f50763          	beq	a0,a5,80002d48 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002d1e:	4785                	li	a5,1
    80002d20:	02f50963          	beq	a0,a5,80002d52 <devintr+0x76>
    return 1;
    80002d24:	4505                	li	a0,1
    } else if(irq){
    80002d26:	d8f1                	beqz	s1,80002cfa <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d28:	85a6                	mv	a1,s1
    80002d2a:	00005517          	auipc	a0,0x5
    80002d2e:	6de50513          	addi	a0,a0,1758 # 80008408 <states.1735+0x38>
    80002d32:	ffffe097          	auipc	ra,0xffffe
    80002d36:	856080e7          	jalr	-1962(ra) # 80000588 <printf>
      plic_complete(irq);
    80002d3a:	8526                	mv	a0,s1
    80002d3c:	00003097          	auipc	ra,0x3
    80002d40:	4c0080e7          	jalr	1216(ra) # 800061fc <plic_complete>
    return 1;
    80002d44:	4505                	li	a0,1
    80002d46:	bf55                	j	80002cfa <devintr+0x1e>
      uartintr();
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	c60080e7          	jalr	-928(ra) # 800009a8 <uartintr>
    80002d50:	b7ed                	j	80002d3a <devintr+0x5e>
      virtio_disk_intr();
    80002d52:	00004097          	auipc	ra,0x4
    80002d56:	98a080e7          	jalr	-1654(ra) # 800066dc <virtio_disk_intr>
    80002d5a:	b7c5                	j	80002d3a <devintr+0x5e>
    if(cpuid() == 0){
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	c28080e7          	jalr	-984(ra) # 80001984 <cpuid>
    80002d64:	c901                	beqz	a0,80002d74 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d66:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d6a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d6c:	14479073          	csrw	sip,a5
    return 2;
    80002d70:	4509                	li	a0,2
    80002d72:	b761                	j	80002cfa <devintr+0x1e>
      clockintr();
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	f22080e7          	jalr	-222(ra) # 80002c96 <clockintr>
    80002d7c:	b7ed                	j	80002d66 <devintr+0x8a>

0000000080002d7e <usertrap>:
{
    80002d7e:	1101                	addi	sp,sp,-32
    80002d80:	ec06                	sd	ra,24(sp)
    80002d82:	e822                	sd	s0,16(sp)
    80002d84:	e426                	sd	s1,8(sp)
    80002d86:	e04a                	sd	s2,0(sp)
    80002d88:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d8a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d8e:	1007f793          	andi	a5,a5,256
    80002d92:	e3ad                	bnez	a5,80002df4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d94:	00003797          	auipc	a5,0x3
    80002d98:	33c78793          	addi	a5,a5,828 # 800060d0 <kernelvec>
    80002d9c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002da0:	fffff097          	auipc	ra,0xfffff
    80002da4:	c10080e7          	jalr	-1008(ra) # 800019b0 <myproc>
    80002da8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002daa:	7d3c                	ld	a5,120(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dac:	14102773          	csrr	a4,sepc
    80002db0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002db6:	47a1                	li	a5,8
    80002db8:	04f71c63          	bne	a4,a5,80002e10 <usertrap+0x92>
    if(p->killed)
    80002dbc:	551c                	lw	a5,40(a0)
    80002dbe:	e3b9                	bnez	a5,80002e04 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002dc0:	7cb8                	ld	a4,120(s1)
    80002dc2:	6f1c                	ld	a5,24(a4)
    80002dc4:	0791                	addi	a5,a5,4
    80002dc6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dcc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dd0:	10079073          	csrw	sstatus,a5
    syscall();
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	2e0080e7          	jalr	736(ra) # 800030b4 <syscall>
  if(p->killed)
    80002ddc:	549c                	lw	a5,40(s1)
    80002dde:	ebc1                	bnez	a5,80002e6e <usertrap+0xf0>
  usertrapret();
    80002de0:	00000097          	auipc	ra,0x0
    80002de4:	e18080e7          	jalr	-488(ra) # 80002bf8 <usertrapret>
}
    80002de8:	60e2                	ld	ra,24(sp)
    80002dea:	6442                	ld	s0,16(sp)
    80002dec:	64a2                	ld	s1,8(sp)
    80002dee:	6902                	ld	s2,0(sp)
    80002df0:	6105                	addi	sp,sp,32
    80002df2:	8082                	ret
    panic("usertrap: not from user mode");
    80002df4:	00005517          	auipc	a0,0x5
    80002df8:	63450513          	addi	a0,a0,1588 # 80008428 <states.1735+0x58>
    80002dfc:	ffffd097          	auipc	ra,0xffffd
    80002e00:	742080e7          	jalr	1858(ra) # 8000053e <panic>
      exit(-1);
    80002e04:	557d                	li	a0,-1
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	46c080e7          	jalr	1132(ra) # 80002272 <exit>
    80002e0e:	bf4d                	j	80002dc0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	ecc080e7          	jalr	-308(ra) # 80002cdc <devintr>
    80002e18:	892a                	mv	s2,a0
    80002e1a:	c501                	beqz	a0,80002e22 <usertrap+0xa4>
  if(p->killed)
    80002e1c:	549c                	lw	a5,40(s1)
    80002e1e:	c3a1                	beqz	a5,80002e5e <usertrap+0xe0>
    80002e20:	a815                	j	80002e54 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e22:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e26:	5890                	lw	a2,48(s1)
    80002e28:	00005517          	auipc	a0,0x5
    80002e2c:	62050513          	addi	a0,a0,1568 # 80008448 <states.1735+0x78>
    80002e30:	ffffd097          	auipc	ra,0xffffd
    80002e34:	758080e7          	jalr	1880(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e38:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e3c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e40:	00005517          	auipc	a0,0x5
    80002e44:	63850513          	addi	a0,a0,1592 # 80008478 <states.1735+0xa8>
    80002e48:	ffffd097          	auipc	ra,0xffffd
    80002e4c:	740080e7          	jalr	1856(ra) # 80000588 <printf>
    p->killed = 1;
    80002e50:	4785                	li	a5,1
    80002e52:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002e54:	557d                	li	a0,-1
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	41c080e7          	jalr	1052(ra) # 80002272 <exit>
  if(which_dev == 2)
    80002e5e:	4789                	li	a5,2
    80002e60:	f8f910e3          	bne	s2,a5,80002de0 <usertrap+0x62>
    yield();
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	176080e7          	jalr	374(ra) # 80001fda <yield>
    80002e6c:	bf95                	j	80002de0 <usertrap+0x62>
  int which_dev = 0;
    80002e6e:	4901                	li	s2,0
    80002e70:	b7d5                	j	80002e54 <usertrap+0xd6>

0000000080002e72 <kerneltrap>:
{
    80002e72:	7179                	addi	sp,sp,-48
    80002e74:	f406                	sd	ra,40(sp)
    80002e76:	f022                	sd	s0,32(sp)
    80002e78:	ec26                	sd	s1,24(sp)
    80002e7a:	e84a                	sd	s2,16(sp)
    80002e7c:	e44e                	sd	s3,8(sp)
    80002e7e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e80:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e84:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e88:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e8c:	1004f793          	andi	a5,s1,256
    80002e90:	cb85                	beqz	a5,80002ec0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e96:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e98:	ef85                	bnez	a5,80002ed0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	e42080e7          	jalr	-446(ra) # 80002cdc <devintr>
    80002ea2:	cd1d                	beqz	a0,80002ee0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ea4:	4789                	li	a5,2
    80002ea6:	06f50a63          	beq	a0,a5,80002f1a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eaa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eae:	10049073          	csrw	sstatus,s1
}
    80002eb2:	70a2                	ld	ra,40(sp)
    80002eb4:	7402                	ld	s0,32(sp)
    80002eb6:	64e2                	ld	s1,24(sp)
    80002eb8:	6942                	ld	s2,16(sp)
    80002eba:	69a2                	ld	s3,8(sp)
    80002ebc:	6145                	addi	sp,sp,48
    80002ebe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ec0:	00005517          	auipc	a0,0x5
    80002ec4:	5d850513          	addi	a0,a0,1496 # 80008498 <states.1735+0xc8>
    80002ec8:	ffffd097          	auipc	ra,0xffffd
    80002ecc:	676080e7          	jalr	1654(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	5f050513          	addi	a0,a0,1520 # 800084c0 <states.1735+0xf0>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	666080e7          	jalr	1638(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ee0:	85ce                	mv	a1,s3
    80002ee2:	00005517          	auipc	a0,0x5
    80002ee6:	5fe50513          	addi	a0,a0,1534 # 800084e0 <states.1735+0x110>
    80002eea:	ffffd097          	auipc	ra,0xffffd
    80002eee:	69e080e7          	jalr	1694(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ef6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002efa:	00005517          	auipc	a0,0x5
    80002efe:	5f650513          	addi	a0,a0,1526 # 800084f0 <states.1735+0x120>
    80002f02:	ffffd097          	auipc	ra,0xffffd
    80002f06:	686080e7          	jalr	1670(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	5fe50513          	addi	a0,a0,1534 # 80008508 <states.1735+0x138>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	62c080e7          	jalr	1580(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f1a:	fffff097          	auipc	ra,0xfffff
    80002f1e:	a96080e7          	jalr	-1386(ra) # 800019b0 <myproc>
    80002f22:	d541                	beqz	a0,80002eaa <kerneltrap+0x38>
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	a8c080e7          	jalr	-1396(ra) # 800019b0 <myproc>
    80002f2c:	4d18                	lw	a4,24(a0)
    80002f2e:	4791                	li	a5,4
    80002f30:	f6f71de3          	bne	a4,a5,80002eaa <kerneltrap+0x38>
    yield();
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	0a6080e7          	jalr	166(ra) # 80001fda <yield>
    80002f3c:	b7bd                	j	80002eaa <kerneltrap+0x38>

0000000080002f3e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	e426                	sd	s1,8(sp)
    80002f46:	1000                	addi	s0,sp,32
    80002f48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	a66080e7          	jalr	-1434(ra) # 800019b0 <myproc>
  switch (n) {
    80002f52:	4795                	li	a5,5
    80002f54:	0497e163          	bltu	a5,s1,80002f96 <argraw+0x58>
    80002f58:	048a                	slli	s1,s1,0x2
    80002f5a:	00005717          	auipc	a4,0x5
    80002f5e:	5e670713          	addi	a4,a4,1510 # 80008540 <states.1735+0x170>
    80002f62:	94ba                	add	s1,s1,a4
    80002f64:	409c                	lw	a5,0(s1)
    80002f66:	97ba                	add	a5,a5,a4
    80002f68:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f6a:	7d3c                	ld	a5,120(a0)
    80002f6c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	64a2                	ld	s1,8(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret
    return p->trapframe->a1;
    80002f78:	7d3c                	ld	a5,120(a0)
    80002f7a:	7fa8                	ld	a0,120(a5)
    80002f7c:	bfcd                	j	80002f6e <argraw+0x30>
    return p->trapframe->a2;
    80002f7e:	7d3c                	ld	a5,120(a0)
    80002f80:	63c8                	ld	a0,128(a5)
    80002f82:	b7f5                	j	80002f6e <argraw+0x30>
    return p->trapframe->a3;
    80002f84:	7d3c                	ld	a5,120(a0)
    80002f86:	67c8                	ld	a0,136(a5)
    80002f88:	b7dd                	j	80002f6e <argraw+0x30>
    return p->trapframe->a4;
    80002f8a:	7d3c                	ld	a5,120(a0)
    80002f8c:	6bc8                	ld	a0,144(a5)
    80002f8e:	b7c5                	j	80002f6e <argraw+0x30>
    return p->trapframe->a5;
    80002f90:	7d3c                	ld	a5,120(a0)
    80002f92:	6fc8                	ld	a0,152(a5)
    80002f94:	bfe9                	j	80002f6e <argraw+0x30>
  panic("argraw");
    80002f96:	00005517          	auipc	a0,0x5
    80002f9a:	58250513          	addi	a0,a0,1410 # 80008518 <states.1735+0x148>
    80002f9e:	ffffd097          	auipc	ra,0xffffd
    80002fa2:	5a0080e7          	jalr	1440(ra) # 8000053e <panic>

0000000080002fa6 <fetchaddr>:
{
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	e04a                	sd	s2,0(sp)
    80002fb0:	1000                	addi	s0,sp,32
    80002fb2:	84aa                	mv	s1,a0
    80002fb4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	9fa080e7          	jalr	-1542(ra) # 800019b0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002fbe:	753c                	ld	a5,104(a0)
    80002fc0:	02f4f863          	bgeu	s1,a5,80002ff0 <fetchaddr+0x4a>
    80002fc4:	00848713          	addi	a4,s1,8
    80002fc8:	02e7e663          	bltu	a5,a4,80002ff4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fcc:	46a1                	li	a3,8
    80002fce:	8626                	mv	a2,s1
    80002fd0:	85ca                	mv	a1,s2
    80002fd2:	7928                	ld	a0,112(a0)
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	72a080e7          	jalr	1834(ra) # 800016fe <copyin>
    80002fdc:	00a03533          	snez	a0,a0
    80002fe0:	40a00533          	neg	a0,a0
}
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	64a2                	ld	s1,8(sp)
    80002fea:	6902                	ld	s2,0(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret
    return -1;
    80002ff0:	557d                	li	a0,-1
    80002ff2:	bfcd                	j	80002fe4 <fetchaddr+0x3e>
    80002ff4:	557d                	li	a0,-1
    80002ff6:	b7fd                	j	80002fe4 <fetchaddr+0x3e>

0000000080002ff8 <fetchstr>:
{
    80002ff8:	7179                	addi	sp,sp,-48
    80002ffa:	f406                	sd	ra,40(sp)
    80002ffc:	f022                	sd	s0,32(sp)
    80002ffe:	ec26                	sd	s1,24(sp)
    80003000:	e84a                	sd	s2,16(sp)
    80003002:	e44e                	sd	s3,8(sp)
    80003004:	1800                	addi	s0,sp,48
    80003006:	892a                	mv	s2,a0
    80003008:	84ae                	mv	s1,a1
    8000300a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	9a4080e7          	jalr	-1628(ra) # 800019b0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003014:	86ce                	mv	a3,s3
    80003016:	864a                	mv	a2,s2
    80003018:	85a6                	mv	a1,s1
    8000301a:	7928                	ld	a0,112(a0)
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	76e080e7          	jalr	1902(ra) # 8000178a <copyinstr>
  if(err < 0)
    80003024:	00054763          	bltz	a0,80003032 <fetchstr+0x3a>
  return strlen(buf);
    80003028:	8526                	mv	a0,s1
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	e3a080e7          	jalr	-454(ra) # 80000e64 <strlen>
}
    80003032:	70a2                	ld	ra,40(sp)
    80003034:	7402                	ld	s0,32(sp)
    80003036:	64e2                	ld	s1,24(sp)
    80003038:	6942                	ld	s2,16(sp)
    8000303a:	69a2                	ld	s3,8(sp)
    8000303c:	6145                	addi	sp,sp,48
    8000303e:	8082                	ret

0000000080003040 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	1000                	addi	s0,sp,32
    8000304a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	ef2080e7          	jalr	-270(ra) # 80002f3e <argraw>
    80003054:	c088                	sw	a0,0(s1)
  return 0;
}
    80003056:	4501                	li	a0,0
    80003058:	60e2                	ld	ra,24(sp)
    8000305a:	6442                	ld	s0,16(sp)
    8000305c:	64a2                	ld	s1,8(sp)
    8000305e:	6105                	addi	sp,sp,32
    80003060:	8082                	ret

0000000080003062 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003062:	1101                	addi	sp,sp,-32
    80003064:	ec06                	sd	ra,24(sp)
    80003066:	e822                	sd	s0,16(sp)
    80003068:	e426                	sd	s1,8(sp)
    8000306a:	1000                	addi	s0,sp,32
    8000306c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	ed0080e7          	jalr	-304(ra) # 80002f3e <argraw>
    80003076:	e088                	sd	a0,0(s1)
  return 0;
}
    80003078:	4501                	li	a0,0
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	64a2                	ld	s1,8(sp)
    80003080:	6105                	addi	sp,sp,32
    80003082:	8082                	ret

0000000080003084 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003084:	1101                	addi	sp,sp,-32
    80003086:	ec06                	sd	ra,24(sp)
    80003088:	e822                	sd	s0,16(sp)
    8000308a:	e426                	sd	s1,8(sp)
    8000308c:	e04a                	sd	s2,0(sp)
    8000308e:	1000                	addi	s0,sp,32
    80003090:	84ae                	mv	s1,a1
    80003092:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003094:	00000097          	auipc	ra,0x0
    80003098:	eaa080e7          	jalr	-342(ra) # 80002f3e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000309c:	864a                	mv	a2,s2
    8000309e:	85a6                	mv	a1,s1
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	f58080e7          	jalr	-168(ra) # 80002ff8 <fetchstr>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6902                	ld	s2,0(sp)
    800030b0:	6105                	addi	sp,sp,32
    800030b2:	8082                	ret

00000000800030b4 <syscall>:
[SYS_print_status] sys_print_status, 
};

void
syscall(void)
{
    800030b4:	1101                	addi	sp,sp,-32
    800030b6:	ec06                	sd	ra,24(sp)
    800030b8:	e822                	sd	s0,16(sp)
    800030ba:	e426                	sd	s1,8(sp)
    800030bc:	e04a                	sd	s2,0(sp)
    800030be:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	8f0080e7          	jalr	-1808(ra) # 800019b0 <myproc>
    800030c8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030ca:	07853903          	ld	s2,120(a0)
    800030ce:	0a893783          	ld	a5,168(s2)
    800030d2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030d6:	37fd                	addiw	a5,a5,-1
    800030d8:	475d                	li	a4,23
    800030da:	00f76f63          	bltu	a4,a5,800030f8 <syscall+0x44>
    800030de:	00369713          	slli	a4,a3,0x3
    800030e2:	00005797          	auipc	a5,0x5
    800030e6:	47678793          	addi	a5,a5,1142 # 80008558 <syscalls>
    800030ea:	97ba                	add	a5,a5,a4
    800030ec:	639c                	ld	a5,0(a5)
    800030ee:	c789                	beqz	a5,800030f8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800030f0:	9782                	jalr	a5
    800030f2:	06a93823          	sd	a0,112(s2)
    800030f6:	a839                	j	80003114 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800030f8:	17848613          	addi	a2,s1,376
    800030fc:	588c                	lw	a1,48(s1)
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	42250513          	addi	a0,a0,1058 # 80008520 <states.1735+0x150>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	482080e7          	jalr	1154(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000310e:	7cbc                	ld	a5,120(s1)
    80003110:	577d                	li	a4,-1
    80003112:	fbb8                	sd	a4,112(a5)
  }
}
    80003114:	60e2                	ld	ra,24(sp)
    80003116:	6442                	ld	s0,16(sp)
    80003118:	64a2                	ld	s1,8(sp)
    8000311a:	6902                	ld	s2,0(sp)
    8000311c:	6105                	addi	sp,sp,32
    8000311e:	8082                	ret

0000000080003120 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003120:	1101                	addi	sp,sp,-32
    80003122:	ec06                	sd	ra,24(sp)
    80003124:	e822                	sd	s0,16(sp)
    80003126:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003128:	fec40593          	addi	a1,s0,-20
    8000312c:	4501                	li	a0,0
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	f12080e7          	jalr	-238(ra) # 80003040 <argint>
    return -1;
    80003136:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003138:	00054963          	bltz	a0,8000314a <sys_exit+0x2a>
  exit(n);
    8000313c:	fec42503          	lw	a0,-20(s0)
    80003140:	fffff097          	auipc	ra,0xfffff
    80003144:	132080e7          	jalr	306(ra) # 80002272 <exit>
  return 0;  // not reached
    80003148:	4781                	li	a5,0
}
    8000314a:	853e                	mv	a0,a5
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret

0000000080003154 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003154:	1141                	addi	sp,sp,-16
    80003156:	e406                	sd	ra,8(sp)
    80003158:	e022                	sd	s0,0(sp)
    8000315a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000315c:	fffff097          	auipc	ra,0xfffff
    80003160:	854080e7          	jalr	-1964(ra) # 800019b0 <myproc>
}
    80003164:	5908                	lw	a0,48(a0)
    80003166:	60a2                	ld	ra,8(sp)
    80003168:	6402                	ld	s0,0(sp)
    8000316a:	0141                	addi	sp,sp,16
    8000316c:	8082                	ret

000000008000316e <sys_fork>:

uint64
sys_fork(void)
{
    8000316e:	1141                	addi	sp,sp,-16
    80003170:	e406                	sd	ra,8(sp)
    80003172:	e022                	sd	s0,0(sp)
    80003174:	0800                	addi	s0,sp,16
  return fork();
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	c52080e7          	jalr	-942(ra) # 80001dc8 <fork>
}
    8000317e:	60a2                	ld	ra,8(sp)
    80003180:	6402                	ld	s0,0(sp)
    80003182:	0141                	addi	sp,sp,16
    80003184:	8082                	ret

0000000080003186 <sys_wait>:

uint64
sys_wait(void)
{
    80003186:	1101                	addi	sp,sp,-32
    80003188:	ec06                	sd	ra,24(sp)
    8000318a:	e822                	sd	s0,16(sp)
    8000318c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000318e:	fe840593          	addi	a1,s0,-24
    80003192:	4501                	li	a0,0
    80003194:	00000097          	auipc	ra,0x0
    80003198:	ece080e7          	jalr	-306(ra) # 80003062 <argaddr>
    8000319c:	87aa                	mv	a5,a0
    return -1;
    8000319e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800031a0:	0007c863          	bltz	a5,800031b0 <sys_wait+0x2a>
  return wait(p);
    800031a4:	fe843503          	ld	a0,-24(s0)
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	ed2080e7          	jalr	-302(ra) # 8000207a <wait>
}
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret

00000000800031b8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800031b8:	7179                	addi	sp,sp,-48
    800031ba:	f406                	sd	ra,40(sp)
    800031bc:	f022                	sd	s0,32(sp)
    800031be:	ec26                	sd	s1,24(sp)
    800031c0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800031c2:	fdc40593          	addi	a1,s0,-36
    800031c6:	4501                	li	a0,0
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	e78080e7          	jalr	-392(ra) # 80003040 <argint>
    800031d0:	87aa                	mv	a5,a0
    return -1;
    800031d2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800031d4:	0207c063          	bltz	a5,800031f4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800031d8:	ffffe097          	auipc	ra,0xffffe
    800031dc:	7d8080e7          	jalr	2008(ra) # 800019b0 <myproc>
    800031e0:	5524                	lw	s1,104(a0)
  if(growproc(n) < 0)
    800031e2:	fdc42503          	lw	a0,-36(s0)
    800031e6:	fffff097          	auipc	ra,0xfffff
    800031ea:	b6e080e7          	jalr	-1170(ra) # 80001d54 <growproc>
    800031ee:	00054863          	bltz	a0,800031fe <sys_sbrk+0x46>
    return -1;
  return addr;
    800031f2:	8526                	mv	a0,s1
}
    800031f4:	70a2                	ld	ra,40(sp)
    800031f6:	7402                	ld	s0,32(sp)
    800031f8:	64e2                	ld	s1,24(sp)
    800031fa:	6145                	addi	sp,sp,48
    800031fc:	8082                	ret
    return -1;
    800031fe:	557d                	li	a0,-1
    80003200:	bfd5                	j	800031f4 <sys_sbrk+0x3c>

0000000080003202 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003202:	7139                	addi	sp,sp,-64
    80003204:	fc06                	sd	ra,56(sp)
    80003206:	f822                	sd	s0,48(sp)
    80003208:	f426                	sd	s1,40(sp)
    8000320a:	f04a                	sd	s2,32(sp)
    8000320c:	ec4e                	sd	s3,24(sp)
    8000320e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003210:	fcc40593          	addi	a1,s0,-52
    80003214:	4501                	li	a0,0
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	e2a080e7          	jalr	-470(ra) # 80003040 <argint>
    return -1;
    8000321e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003220:	06054563          	bltz	a0,8000328a <sys_sleep+0x88>
  acquire(&tickslock);
    80003224:	00014517          	auipc	a0,0x14
    80003228:	6cc50513          	addi	a0,a0,1740 # 800178f0 <tickslock>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	9b8080e7          	jalr	-1608(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80003234:	00006917          	auipc	s2,0x6
    80003238:	e2492903          	lw	s2,-476(s2) # 80009058 <ticks>
  while(ticks - ticks0 < n){
    8000323c:	fcc42783          	lw	a5,-52(s0)
    80003240:	cf85                	beqz	a5,80003278 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003242:	00014997          	auipc	s3,0x14
    80003246:	6ae98993          	addi	s3,s3,1710 # 800178f0 <tickslock>
    8000324a:	00006497          	auipc	s1,0x6
    8000324e:	e0e48493          	addi	s1,s1,-498 # 80009058 <ticks>
    if(myproc()->killed){
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	75e080e7          	jalr	1886(ra) # 800019b0 <myproc>
    8000325a:	551c                	lw	a5,40(a0)
    8000325c:	ef9d                	bnez	a5,8000329a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000325e:	85ce                	mv	a1,s3
    80003260:	8526                	mv	a0,s1
    80003262:	fffff097          	auipc	ra,0xfffff
    80003266:	db4080e7          	jalr	-588(ra) # 80002016 <sleep>
  while(ticks - ticks0 < n){
    8000326a:	409c                	lw	a5,0(s1)
    8000326c:	412787bb          	subw	a5,a5,s2
    80003270:	fcc42703          	lw	a4,-52(s0)
    80003274:	fce7efe3          	bltu	a5,a4,80003252 <sys_sleep+0x50>
  }
  release(&tickslock);
    80003278:	00014517          	auipc	a0,0x14
    8000327c:	67850513          	addi	a0,a0,1656 # 800178f0 <tickslock>
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	a18080e7          	jalr	-1512(ra) # 80000c98 <release>
  return 0;
    80003288:	4781                	li	a5,0
}
    8000328a:	853e                	mv	a0,a5
    8000328c:	70e2                	ld	ra,56(sp)
    8000328e:	7442                	ld	s0,48(sp)
    80003290:	74a2                	ld	s1,40(sp)
    80003292:	7902                	ld	s2,32(sp)
    80003294:	69e2                	ld	s3,24(sp)
    80003296:	6121                	addi	sp,sp,64
    80003298:	8082                	ret
      release(&tickslock);
    8000329a:	00014517          	auipc	a0,0x14
    8000329e:	65650513          	addi	a0,a0,1622 # 800178f0 <tickslock>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	9f6080e7          	jalr	-1546(ra) # 80000c98 <release>
      return -1;
    800032aa:	57fd                	li	a5,-1
    800032ac:	bff9                	j	8000328a <sys_sleep+0x88>

00000000800032ae <sys_kill>:

uint64
sys_kill(void)
{
    800032ae:	1101                	addi	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800032b6:	fec40593          	addi	a1,s0,-20
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	d84080e7          	jalr	-636(ra) # 80003040 <argint>
    800032c4:	87aa                	mv	a5,a0
    return -1;
    800032c6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800032c8:	0007c863          	bltz	a5,800032d8 <sys_kill+0x2a>
  return kill(pid);
    800032cc:	fec42503          	lw	a0,-20(s0)
    800032d0:	fffff097          	auipc	ra,0xfffff
    800032d4:	122080e7          	jalr	290(ra) # 800023f2 <kill>
}
    800032d8:	60e2                	ld	ra,24(sp)
    800032da:	6442                	ld	s0,16(sp)
    800032dc:	6105                	addi	sp,sp,32
    800032de:	8082                	ret

00000000800032e0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032e0:	1101                	addi	sp,sp,-32
    800032e2:	ec06                	sd	ra,24(sp)
    800032e4:	e822                	sd	s0,16(sp)
    800032e6:	e426                	sd	s1,8(sp)
    800032e8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800032ea:	00014517          	auipc	a0,0x14
    800032ee:	60650513          	addi	a0,a0,1542 # 800178f0 <tickslock>
    800032f2:	ffffe097          	auipc	ra,0xffffe
    800032f6:	8f2080e7          	jalr	-1806(ra) # 80000be4 <acquire>
  xticks = ticks;
    800032fa:	00006497          	auipc	s1,0x6
    800032fe:	d5e4a483          	lw	s1,-674(s1) # 80009058 <ticks>
  release(&tickslock);
    80003302:	00014517          	auipc	a0,0x14
    80003306:	5ee50513          	addi	a0,a0,1518 # 800178f0 <tickslock>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	98e080e7          	jalr	-1650(ra) # 80000c98 <release>
  return xticks;
}
    80003312:	02049513          	slli	a0,s1,0x20
    80003316:	9101                	srli	a0,a0,0x20
    80003318:	60e2                	ld	ra,24(sp)
    8000331a:	6442                	ld	s0,16(sp)
    8000331c:	64a2                	ld	s1,8(sp)
    8000331e:	6105                	addi	sp,sp,32
    80003320:	8082                	ret

0000000080003322 <sys_pause_system>:
uint64
sys_pause_system(void)
{
    80003322:	1101                	addi	sp,sp,-32
    80003324:	ec06                	sd	ra,24(sp)
    80003326:	e822                	sd	s0,16(sp)
    80003328:	1000                	addi	s0,sp,32
  int sec;

  if(argint(0, &sec) < 0)
    8000332a:	fec40593          	addi	a1,s0,-20
    8000332e:	4501                	li	a0,0
    80003330:	00000097          	auipc	ra,0x0
    80003334:	d10080e7          	jalr	-752(ra) # 80003040 <argint>
    80003338:	87aa                	mv	a5,a0
    return -1;
    8000333a:	557d                	li	a0,-1
  if(argint(0, &sec) < 0)
    8000333c:	0007c863          	bltz	a5,8000334c <sys_pause_system+0x2a>
  return pause_system(sec);
    80003340:	fec42503          	lw	a0,-20(s0)
    80003344:	fffff097          	auipc	ra,0xfffff
    80003348:	69a080e7          	jalr	1690(ra) # 800029de <pause_system>
}
    8000334c:	60e2                	ld	ra,24(sp)
    8000334e:	6442                	ld	s0,16(sp)
    80003350:	6105                	addi	sp,sp,32
    80003352:	8082                	ret

0000000080003354 <sys_kill_system>:
uint64
sys_kill_system(void)
{
    80003354:	1141                	addi	sp,sp,-16
    80003356:	e406                	sd	ra,8(sp)
    80003358:	e022                	sd	s0,0(sp)
    8000335a:	0800                	addi	s0,sp,16
  return kill_system();
    8000335c:	fffff097          	auipc	ra,0xfffff
    80003360:	6d4080e7          	jalr	1748(ra) # 80002a30 <kill_system>
}
    80003364:	60a2                	ld	ra,8(sp)
    80003366:	6402                	ld	s0,0(sp)
    80003368:	0141                	addi	sp,sp,16
    8000336a:	8082                	ret

000000008000336c <sys_print_status>:

uint64
sys_print_status(void)
{
    8000336c:	1141                	addi	sp,sp,-16
    8000336e:	e406                	sd	ra,8(sp)
    80003370:	e022                	sd	s0,0(sp)
    80003372:	0800                	addi	s0,sp,16
  return print_sys_status();
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	750080e7          	jalr	1872(ra) # 80002ac4 <print_sys_status>
    8000337c:	60a2                	ld	ra,8(sp)
    8000337e:	6402                	ld	s0,0(sp)
    80003380:	0141                	addi	sp,sp,16
    80003382:	8082                	ret

0000000080003384 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003384:	7179                	addi	sp,sp,-48
    80003386:	f406                	sd	ra,40(sp)
    80003388:	f022                	sd	s0,32(sp)
    8000338a:	ec26                	sd	s1,24(sp)
    8000338c:	e84a                	sd	s2,16(sp)
    8000338e:	e44e                	sd	s3,8(sp)
    80003390:	e052                	sd	s4,0(sp)
    80003392:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003394:	00005597          	auipc	a1,0x5
    80003398:	28c58593          	addi	a1,a1,652 # 80008620 <syscalls+0xc8>
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	56c50513          	addi	a0,a0,1388 # 80017908 <bcache>
    800033a4:	ffffd097          	auipc	ra,0xffffd
    800033a8:	7b0080e7          	jalr	1968(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800033ac:	0001c797          	auipc	a5,0x1c
    800033b0:	55c78793          	addi	a5,a5,1372 # 8001f908 <bcache+0x8000>
    800033b4:	0001c717          	auipc	a4,0x1c
    800033b8:	7bc70713          	addi	a4,a4,1980 # 8001fb70 <bcache+0x8268>
    800033bc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033c0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033c4:	00014497          	auipc	s1,0x14
    800033c8:	55c48493          	addi	s1,s1,1372 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800033cc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033ce:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033d0:	00005a17          	auipc	s4,0x5
    800033d4:	258a0a13          	addi	s4,s4,600 # 80008628 <syscalls+0xd0>
    b->next = bcache.head.next;
    800033d8:	2b893783          	ld	a5,696(s2)
    800033dc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033de:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033e2:	85d2                	mv	a1,s4
    800033e4:	01048513          	addi	a0,s1,16
    800033e8:	00001097          	auipc	ra,0x1
    800033ec:	4bc080e7          	jalr	1212(ra) # 800048a4 <initsleeplock>
    bcache.head.next->prev = b;
    800033f0:	2b893783          	ld	a5,696(s2)
    800033f4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033f6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033fa:	45848493          	addi	s1,s1,1112
    800033fe:	fd349de3          	bne	s1,s3,800033d8 <binit+0x54>
  }
}
    80003402:	70a2                	ld	ra,40(sp)
    80003404:	7402                	ld	s0,32(sp)
    80003406:	64e2                	ld	s1,24(sp)
    80003408:	6942                	ld	s2,16(sp)
    8000340a:	69a2                	ld	s3,8(sp)
    8000340c:	6a02                	ld	s4,0(sp)
    8000340e:	6145                	addi	sp,sp,48
    80003410:	8082                	ret

0000000080003412 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003412:	7179                	addi	sp,sp,-48
    80003414:	f406                	sd	ra,40(sp)
    80003416:	f022                	sd	s0,32(sp)
    80003418:	ec26                	sd	s1,24(sp)
    8000341a:	e84a                	sd	s2,16(sp)
    8000341c:	e44e                	sd	s3,8(sp)
    8000341e:	1800                	addi	s0,sp,48
    80003420:	89aa                	mv	s3,a0
    80003422:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003424:	00014517          	auipc	a0,0x14
    80003428:	4e450513          	addi	a0,a0,1252 # 80017908 <bcache>
    8000342c:	ffffd097          	auipc	ra,0xffffd
    80003430:	7b8080e7          	jalr	1976(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003434:	0001c497          	auipc	s1,0x1c
    80003438:	78c4b483          	ld	s1,1932(s1) # 8001fbc0 <bcache+0x82b8>
    8000343c:	0001c797          	auipc	a5,0x1c
    80003440:	73478793          	addi	a5,a5,1844 # 8001fb70 <bcache+0x8268>
    80003444:	02f48f63          	beq	s1,a5,80003482 <bread+0x70>
    80003448:	873e                	mv	a4,a5
    8000344a:	a021                	j	80003452 <bread+0x40>
    8000344c:	68a4                	ld	s1,80(s1)
    8000344e:	02e48a63          	beq	s1,a4,80003482 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003452:	449c                	lw	a5,8(s1)
    80003454:	ff379ce3          	bne	a5,s3,8000344c <bread+0x3a>
    80003458:	44dc                	lw	a5,12(s1)
    8000345a:	ff2799e3          	bne	a5,s2,8000344c <bread+0x3a>
      b->refcnt++;
    8000345e:	40bc                	lw	a5,64(s1)
    80003460:	2785                	addiw	a5,a5,1
    80003462:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003464:	00014517          	auipc	a0,0x14
    80003468:	4a450513          	addi	a0,a0,1188 # 80017908 <bcache>
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	82c080e7          	jalr	-2004(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003474:	01048513          	addi	a0,s1,16
    80003478:	00001097          	auipc	ra,0x1
    8000347c:	466080e7          	jalr	1126(ra) # 800048de <acquiresleep>
      return b;
    80003480:	a8b9                	j	800034de <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003482:	0001c497          	auipc	s1,0x1c
    80003486:	7364b483          	ld	s1,1846(s1) # 8001fbb8 <bcache+0x82b0>
    8000348a:	0001c797          	auipc	a5,0x1c
    8000348e:	6e678793          	addi	a5,a5,1766 # 8001fb70 <bcache+0x8268>
    80003492:	00f48863          	beq	s1,a5,800034a2 <bread+0x90>
    80003496:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003498:	40bc                	lw	a5,64(s1)
    8000349a:	cf81                	beqz	a5,800034b2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000349c:	64a4                	ld	s1,72(s1)
    8000349e:	fee49de3          	bne	s1,a4,80003498 <bread+0x86>
  panic("bget: no buffers");
    800034a2:	00005517          	auipc	a0,0x5
    800034a6:	18e50513          	addi	a0,a0,398 # 80008630 <syscalls+0xd8>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	094080e7          	jalr	148(ra) # 8000053e <panic>
      b->dev = dev;
    800034b2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800034b6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800034ba:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034be:	4785                	li	a5,1
    800034c0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034c2:	00014517          	auipc	a0,0x14
    800034c6:	44650513          	addi	a0,a0,1094 # 80017908 <bcache>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	7ce080e7          	jalr	1998(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    800034d2:	01048513          	addi	a0,s1,16
    800034d6:	00001097          	auipc	ra,0x1
    800034da:	408080e7          	jalr	1032(ra) # 800048de <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034de:	409c                	lw	a5,0(s1)
    800034e0:	cb89                	beqz	a5,800034f2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034e2:	8526                	mv	a0,s1
    800034e4:	70a2                	ld	ra,40(sp)
    800034e6:	7402                	ld	s0,32(sp)
    800034e8:	64e2                	ld	s1,24(sp)
    800034ea:	6942                	ld	s2,16(sp)
    800034ec:	69a2                	ld	s3,8(sp)
    800034ee:	6145                	addi	sp,sp,48
    800034f0:	8082                	ret
    virtio_disk_rw(b, 0);
    800034f2:	4581                	li	a1,0
    800034f4:	8526                	mv	a0,s1
    800034f6:	00003097          	auipc	ra,0x3
    800034fa:	f10080e7          	jalr	-240(ra) # 80006406 <virtio_disk_rw>
    b->valid = 1;
    800034fe:	4785                	li	a5,1
    80003500:	c09c                	sw	a5,0(s1)
  return b;
    80003502:	b7c5                	j	800034e2 <bread+0xd0>

0000000080003504 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003504:	1101                	addi	sp,sp,-32
    80003506:	ec06                	sd	ra,24(sp)
    80003508:	e822                	sd	s0,16(sp)
    8000350a:	e426                	sd	s1,8(sp)
    8000350c:	1000                	addi	s0,sp,32
    8000350e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003510:	0541                	addi	a0,a0,16
    80003512:	00001097          	auipc	ra,0x1
    80003516:	466080e7          	jalr	1126(ra) # 80004978 <holdingsleep>
    8000351a:	cd01                	beqz	a0,80003532 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000351c:	4585                	li	a1,1
    8000351e:	8526                	mv	a0,s1
    80003520:	00003097          	auipc	ra,0x3
    80003524:	ee6080e7          	jalr	-282(ra) # 80006406 <virtio_disk_rw>
}
    80003528:	60e2                	ld	ra,24(sp)
    8000352a:	6442                	ld	s0,16(sp)
    8000352c:	64a2                	ld	s1,8(sp)
    8000352e:	6105                	addi	sp,sp,32
    80003530:	8082                	ret
    panic("bwrite");
    80003532:	00005517          	auipc	a0,0x5
    80003536:	11650513          	addi	a0,a0,278 # 80008648 <syscalls+0xf0>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	004080e7          	jalr	4(ra) # 8000053e <panic>

0000000080003542 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003542:	1101                	addi	sp,sp,-32
    80003544:	ec06                	sd	ra,24(sp)
    80003546:	e822                	sd	s0,16(sp)
    80003548:	e426                	sd	s1,8(sp)
    8000354a:	e04a                	sd	s2,0(sp)
    8000354c:	1000                	addi	s0,sp,32
    8000354e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003550:	01050913          	addi	s2,a0,16
    80003554:	854a                	mv	a0,s2
    80003556:	00001097          	auipc	ra,0x1
    8000355a:	422080e7          	jalr	1058(ra) # 80004978 <holdingsleep>
    8000355e:	c92d                	beqz	a0,800035d0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003560:	854a                	mv	a0,s2
    80003562:	00001097          	auipc	ra,0x1
    80003566:	3d2080e7          	jalr	978(ra) # 80004934 <releasesleep>

  acquire(&bcache.lock);
    8000356a:	00014517          	auipc	a0,0x14
    8000356e:	39e50513          	addi	a0,a0,926 # 80017908 <bcache>
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	672080e7          	jalr	1650(ra) # 80000be4 <acquire>
  b->refcnt--;
    8000357a:	40bc                	lw	a5,64(s1)
    8000357c:	37fd                	addiw	a5,a5,-1
    8000357e:	0007871b          	sext.w	a4,a5
    80003582:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003584:	eb05                	bnez	a4,800035b4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003586:	68bc                	ld	a5,80(s1)
    80003588:	64b8                	ld	a4,72(s1)
    8000358a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000358c:	64bc                	ld	a5,72(s1)
    8000358e:	68b8                	ld	a4,80(s1)
    80003590:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003592:	0001c797          	auipc	a5,0x1c
    80003596:	37678793          	addi	a5,a5,886 # 8001f908 <bcache+0x8000>
    8000359a:	2b87b703          	ld	a4,696(a5)
    8000359e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800035a0:	0001c717          	auipc	a4,0x1c
    800035a4:	5d070713          	addi	a4,a4,1488 # 8001fb70 <bcache+0x8268>
    800035a8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800035aa:	2b87b703          	ld	a4,696(a5)
    800035ae:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035b0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035b4:	00014517          	auipc	a0,0x14
    800035b8:	35450513          	addi	a0,a0,852 # 80017908 <bcache>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	6dc080e7          	jalr	1756(ra) # 80000c98 <release>
}
    800035c4:	60e2                	ld	ra,24(sp)
    800035c6:	6442                	ld	s0,16(sp)
    800035c8:	64a2                	ld	s1,8(sp)
    800035ca:	6902                	ld	s2,0(sp)
    800035cc:	6105                	addi	sp,sp,32
    800035ce:	8082                	ret
    panic("brelse");
    800035d0:	00005517          	auipc	a0,0x5
    800035d4:	08050513          	addi	a0,a0,128 # 80008650 <syscalls+0xf8>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	f66080e7          	jalr	-154(ra) # 8000053e <panic>

00000000800035e0 <bpin>:

void
bpin(struct buf *b) {
    800035e0:	1101                	addi	sp,sp,-32
    800035e2:	ec06                	sd	ra,24(sp)
    800035e4:	e822                	sd	s0,16(sp)
    800035e6:	e426                	sd	s1,8(sp)
    800035e8:	1000                	addi	s0,sp,32
    800035ea:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035ec:	00014517          	auipc	a0,0x14
    800035f0:	31c50513          	addi	a0,a0,796 # 80017908 <bcache>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  b->refcnt++;
    800035fc:	40bc                	lw	a5,64(s1)
    800035fe:	2785                	addiw	a5,a5,1
    80003600:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003602:	00014517          	auipc	a0,0x14
    80003606:	30650513          	addi	a0,a0,774 # 80017908 <bcache>
    8000360a:	ffffd097          	auipc	ra,0xffffd
    8000360e:	68e080e7          	jalr	1678(ra) # 80000c98 <release>
}
    80003612:	60e2                	ld	ra,24(sp)
    80003614:	6442                	ld	s0,16(sp)
    80003616:	64a2                	ld	s1,8(sp)
    80003618:	6105                	addi	sp,sp,32
    8000361a:	8082                	ret

000000008000361c <bunpin>:

void
bunpin(struct buf *b) {
    8000361c:	1101                	addi	sp,sp,-32
    8000361e:	ec06                	sd	ra,24(sp)
    80003620:	e822                	sd	s0,16(sp)
    80003622:	e426                	sd	s1,8(sp)
    80003624:	1000                	addi	s0,sp,32
    80003626:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003628:	00014517          	auipc	a0,0x14
    8000362c:	2e050513          	addi	a0,a0,736 # 80017908 <bcache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	5b4080e7          	jalr	1460(ra) # 80000be4 <acquire>
  b->refcnt--;
    80003638:	40bc                	lw	a5,64(s1)
    8000363a:	37fd                	addiw	a5,a5,-1
    8000363c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000363e:	00014517          	auipc	a0,0x14
    80003642:	2ca50513          	addi	a0,a0,714 # 80017908 <bcache>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	652080e7          	jalr	1618(ra) # 80000c98 <release>
}
    8000364e:	60e2                	ld	ra,24(sp)
    80003650:	6442                	ld	s0,16(sp)
    80003652:	64a2                	ld	s1,8(sp)
    80003654:	6105                	addi	sp,sp,32
    80003656:	8082                	ret

0000000080003658 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003658:	1101                	addi	sp,sp,-32
    8000365a:	ec06                	sd	ra,24(sp)
    8000365c:	e822                	sd	s0,16(sp)
    8000365e:	e426                	sd	s1,8(sp)
    80003660:	e04a                	sd	s2,0(sp)
    80003662:	1000                	addi	s0,sp,32
    80003664:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003666:	00d5d59b          	srliw	a1,a1,0xd
    8000366a:	0001d797          	auipc	a5,0x1d
    8000366e:	97a7a783          	lw	a5,-1670(a5) # 8001ffe4 <sb+0x1c>
    80003672:	9dbd                	addw	a1,a1,a5
    80003674:	00000097          	auipc	ra,0x0
    80003678:	d9e080e7          	jalr	-610(ra) # 80003412 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000367c:	0074f713          	andi	a4,s1,7
    80003680:	4785                	li	a5,1
    80003682:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003686:	14ce                	slli	s1,s1,0x33
    80003688:	90d9                	srli	s1,s1,0x36
    8000368a:	00950733          	add	a4,a0,s1
    8000368e:	05874703          	lbu	a4,88(a4)
    80003692:	00e7f6b3          	and	a3,a5,a4
    80003696:	c69d                	beqz	a3,800036c4 <bfree+0x6c>
    80003698:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000369a:	94aa                	add	s1,s1,a0
    8000369c:	fff7c793          	not	a5,a5
    800036a0:	8ff9                	and	a5,a5,a4
    800036a2:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800036a6:	00001097          	auipc	ra,0x1
    800036aa:	118080e7          	jalr	280(ra) # 800047be <log_write>
  brelse(bp);
    800036ae:	854a                	mv	a0,s2
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	e92080e7          	jalr	-366(ra) # 80003542 <brelse>
}
    800036b8:	60e2                	ld	ra,24(sp)
    800036ba:	6442                	ld	s0,16(sp)
    800036bc:	64a2                	ld	s1,8(sp)
    800036be:	6902                	ld	s2,0(sp)
    800036c0:	6105                	addi	sp,sp,32
    800036c2:	8082                	ret
    panic("freeing free block");
    800036c4:	00005517          	auipc	a0,0x5
    800036c8:	f9450513          	addi	a0,a0,-108 # 80008658 <syscalls+0x100>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	e72080e7          	jalr	-398(ra) # 8000053e <panic>

00000000800036d4 <balloc>:
{
    800036d4:	711d                	addi	sp,sp,-96
    800036d6:	ec86                	sd	ra,88(sp)
    800036d8:	e8a2                	sd	s0,80(sp)
    800036da:	e4a6                	sd	s1,72(sp)
    800036dc:	e0ca                	sd	s2,64(sp)
    800036de:	fc4e                	sd	s3,56(sp)
    800036e0:	f852                	sd	s4,48(sp)
    800036e2:	f456                	sd	s5,40(sp)
    800036e4:	f05a                	sd	s6,32(sp)
    800036e6:	ec5e                	sd	s7,24(sp)
    800036e8:	e862                	sd	s8,16(sp)
    800036ea:	e466                	sd	s9,8(sp)
    800036ec:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036ee:	0001d797          	auipc	a5,0x1d
    800036f2:	8de7a783          	lw	a5,-1826(a5) # 8001ffcc <sb+0x4>
    800036f6:	cbd1                	beqz	a5,8000378a <balloc+0xb6>
    800036f8:	8baa                	mv	s7,a0
    800036fa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036fc:	0001db17          	auipc	s6,0x1d
    80003700:	8ccb0b13          	addi	s6,s6,-1844 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003704:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003706:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003708:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000370a:	6c89                	lui	s9,0x2
    8000370c:	a831                	j	80003728 <balloc+0x54>
    brelse(bp);
    8000370e:	854a                	mv	a0,s2
    80003710:	00000097          	auipc	ra,0x0
    80003714:	e32080e7          	jalr	-462(ra) # 80003542 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003718:	015c87bb          	addw	a5,s9,s5
    8000371c:	00078a9b          	sext.w	s5,a5
    80003720:	004b2703          	lw	a4,4(s6)
    80003724:	06eaf363          	bgeu	s5,a4,8000378a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003728:	41fad79b          	sraiw	a5,s5,0x1f
    8000372c:	0137d79b          	srliw	a5,a5,0x13
    80003730:	015787bb          	addw	a5,a5,s5
    80003734:	40d7d79b          	sraiw	a5,a5,0xd
    80003738:	01cb2583          	lw	a1,28(s6)
    8000373c:	9dbd                	addw	a1,a1,a5
    8000373e:	855e                	mv	a0,s7
    80003740:	00000097          	auipc	ra,0x0
    80003744:	cd2080e7          	jalr	-814(ra) # 80003412 <bread>
    80003748:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000374a:	004b2503          	lw	a0,4(s6)
    8000374e:	000a849b          	sext.w	s1,s5
    80003752:	8662                	mv	a2,s8
    80003754:	faa4fde3          	bgeu	s1,a0,8000370e <balloc+0x3a>
      m = 1 << (bi % 8);
    80003758:	41f6579b          	sraiw	a5,a2,0x1f
    8000375c:	01d7d69b          	srliw	a3,a5,0x1d
    80003760:	00c6873b          	addw	a4,a3,a2
    80003764:	00777793          	andi	a5,a4,7
    80003768:	9f95                	subw	a5,a5,a3
    8000376a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000376e:	4037571b          	sraiw	a4,a4,0x3
    80003772:	00e906b3          	add	a3,s2,a4
    80003776:	0586c683          	lbu	a3,88(a3)
    8000377a:	00d7f5b3          	and	a1,a5,a3
    8000377e:	cd91                	beqz	a1,8000379a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003780:	2605                	addiw	a2,a2,1
    80003782:	2485                	addiw	s1,s1,1
    80003784:	fd4618e3          	bne	a2,s4,80003754 <balloc+0x80>
    80003788:	b759                	j	8000370e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000378a:	00005517          	auipc	a0,0x5
    8000378e:	ee650513          	addi	a0,a0,-282 # 80008670 <syscalls+0x118>
    80003792:	ffffd097          	auipc	ra,0xffffd
    80003796:	dac080e7          	jalr	-596(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000379a:	974a                	add	a4,a4,s2
    8000379c:	8fd5                	or	a5,a5,a3
    8000379e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800037a2:	854a                	mv	a0,s2
    800037a4:	00001097          	auipc	ra,0x1
    800037a8:	01a080e7          	jalr	26(ra) # 800047be <log_write>
        brelse(bp);
    800037ac:	854a                	mv	a0,s2
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	d94080e7          	jalr	-620(ra) # 80003542 <brelse>
  bp = bread(dev, bno);
    800037b6:	85a6                	mv	a1,s1
    800037b8:	855e                	mv	a0,s7
    800037ba:	00000097          	auipc	ra,0x0
    800037be:	c58080e7          	jalr	-936(ra) # 80003412 <bread>
    800037c2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037c4:	40000613          	li	a2,1024
    800037c8:	4581                	li	a1,0
    800037ca:	05850513          	addi	a0,a0,88
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	512080e7          	jalr	1298(ra) # 80000ce0 <memset>
  log_write(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00001097          	auipc	ra,0x1
    800037dc:	fe6080e7          	jalr	-26(ra) # 800047be <log_write>
  brelse(bp);
    800037e0:	854a                	mv	a0,s2
    800037e2:	00000097          	auipc	ra,0x0
    800037e6:	d60080e7          	jalr	-672(ra) # 80003542 <brelse>
}
    800037ea:	8526                	mv	a0,s1
    800037ec:	60e6                	ld	ra,88(sp)
    800037ee:	6446                	ld	s0,80(sp)
    800037f0:	64a6                	ld	s1,72(sp)
    800037f2:	6906                	ld	s2,64(sp)
    800037f4:	79e2                	ld	s3,56(sp)
    800037f6:	7a42                	ld	s4,48(sp)
    800037f8:	7aa2                	ld	s5,40(sp)
    800037fa:	7b02                	ld	s6,32(sp)
    800037fc:	6be2                	ld	s7,24(sp)
    800037fe:	6c42                	ld	s8,16(sp)
    80003800:	6ca2                	ld	s9,8(sp)
    80003802:	6125                	addi	sp,sp,96
    80003804:	8082                	ret

0000000080003806 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003806:	7179                	addi	sp,sp,-48
    80003808:	f406                	sd	ra,40(sp)
    8000380a:	f022                	sd	s0,32(sp)
    8000380c:	ec26                	sd	s1,24(sp)
    8000380e:	e84a                	sd	s2,16(sp)
    80003810:	e44e                	sd	s3,8(sp)
    80003812:	e052                	sd	s4,0(sp)
    80003814:	1800                	addi	s0,sp,48
    80003816:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003818:	47ad                	li	a5,11
    8000381a:	04b7fe63          	bgeu	a5,a1,80003876 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000381e:	ff45849b          	addiw	s1,a1,-12
    80003822:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003826:	0ff00793          	li	a5,255
    8000382a:	0ae7e363          	bltu	a5,a4,800038d0 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000382e:	08052583          	lw	a1,128(a0)
    80003832:	c5ad                	beqz	a1,8000389c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003834:	00092503          	lw	a0,0(s2)
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	bda080e7          	jalr	-1062(ra) # 80003412 <bread>
    80003840:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003842:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003846:	02049593          	slli	a1,s1,0x20
    8000384a:	9181                	srli	a1,a1,0x20
    8000384c:	058a                	slli	a1,a1,0x2
    8000384e:	00b784b3          	add	s1,a5,a1
    80003852:	0004a983          	lw	s3,0(s1)
    80003856:	04098d63          	beqz	s3,800038b0 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000385a:	8552                	mv	a0,s4
    8000385c:	00000097          	auipc	ra,0x0
    80003860:	ce6080e7          	jalr	-794(ra) # 80003542 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003864:	854e                	mv	a0,s3
    80003866:	70a2                	ld	ra,40(sp)
    80003868:	7402                	ld	s0,32(sp)
    8000386a:	64e2                	ld	s1,24(sp)
    8000386c:	6942                	ld	s2,16(sp)
    8000386e:	69a2                	ld	s3,8(sp)
    80003870:	6a02                	ld	s4,0(sp)
    80003872:	6145                	addi	sp,sp,48
    80003874:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003876:	02059493          	slli	s1,a1,0x20
    8000387a:	9081                	srli	s1,s1,0x20
    8000387c:	048a                	slli	s1,s1,0x2
    8000387e:	94aa                	add	s1,s1,a0
    80003880:	0504a983          	lw	s3,80(s1)
    80003884:	fe0990e3          	bnez	s3,80003864 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003888:	4108                	lw	a0,0(a0)
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	e4a080e7          	jalr	-438(ra) # 800036d4 <balloc>
    80003892:	0005099b          	sext.w	s3,a0
    80003896:	0534a823          	sw	s3,80(s1)
    8000389a:	b7e9                	j	80003864 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000389c:	4108                	lw	a0,0(a0)
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	e36080e7          	jalr	-458(ra) # 800036d4 <balloc>
    800038a6:	0005059b          	sext.w	a1,a0
    800038aa:	08b92023          	sw	a1,128(s2)
    800038ae:	b759                	j	80003834 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800038b0:	00092503          	lw	a0,0(s2)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	e20080e7          	jalr	-480(ra) # 800036d4 <balloc>
    800038bc:	0005099b          	sext.w	s3,a0
    800038c0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800038c4:	8552                	mv	a0,s4
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	ef8080e7          	jalr	-264(ra) # 800047be <log_write>
    800038ce:	b771                	j	8000385a <bmap+0x54>
  panic("bmap: out of range");
    800038d0:	00005517          	auipc	a0,0x5
    800038d4:	db850513          	addi	a0,a0,-584 # 80008688 <syscalls+0x130>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	c66080e7          	jalr	-922(ra) # 8000053e <panic>

00000000800038e0 <iget>:
{
    800038e0:	7179                	addi	sp,sp,-48
    800038e2:	f406                	sd	ra,40(sp)
    800038e4:	f022                	sd	s0,32(sp)
    800038e6:	ec26                	sd	s1,24(sp)
    800038e8:	e84a                	sd	s2,16(sp)
    800038ea:	e44e                	sd	s3,8(sp)
    800038ec:	e052                	sd	s4,0(sp)
    800038ee:	1800                	addi	s0,sp,48
    800038f0:	89aa                	mv	s3,a0
    800038f2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038f4:	0001c517          	auipc	a0,0x1c
    800038f8:	6f450513          	addi	a0,a0,1780 # 8001ffe8 <itable>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	2e8080e7          	jalr	744(ra) # 80000be4 <acquire>
  empty = 0;
    80003904:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003906:	0001c497          	auipc	s1,0x1c
    8000390a:	6fa48493          	addi	s1,s1,1786 # 80020000 <itable+0x18>
    8000390e:	0001e697          	auipc	a3,0x1e
    80003912:	18268693          	addi	a3,a3,386 # 80021a90 <log>
    80003916:	a039                	j	80003924 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003918:	02090b63          	beqz	s2,8000394e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000391c:	08848493          	addi	s1,s1,136
    80003920:	02d48a63          	beq	s1,a3,80003954 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003924:	449c                	lw	a5,8(s1)
    80003926:	fef059e3          	blez	a5,80003918 <iget+0x38>
    8000392a:	4098                	lw	a4,0(s1)
    8000392c:	ff3716e3          	bne	a4,s3,80003918 <iget+0x38>
    80003930:	40d8                	lw	a4,4(s1)
    80003932:	ff4713e3          	bne	a4,s4,80003918 <iget+0x38>
      ip->ref++;
    80003936:	2785                	addiw	a5,a5,1
    80003938:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000393a:	0001c517          	auipc	a0,0x1c
    8000393e:	6ae50513          	addi	a0,a0,1710 # 8001ffe8 <itable>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	356080e7          	jalr	854(ra) # 80000c98 <release>
      return ip;
    8000394a:	8926                	mv	s2,s1
    8000394c:	a03d                	j	8000397a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000394e:	f7f9                	bnez	a5,8000391c <iget+0x3c>
    80003950:	8926                	mv	s2,s1
    80003952:	b7e9                	j	8000391c <iget+0x3c>
  if(empty == 0)
    80003954:	02090c63          	beqz	s2,8000398c <iget+0xac>
  ip->dev = dev;
    80003958:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000395c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003960:	4785                	li	a5,1
    80003962:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003966:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000396a:	0001c517          	auipc	a0,0x1c
    8000396e:	67e50513          	addi	a0,a0,1662 # 8001ffe8 <itable>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	326080e7          	jalr	806(ra) # 80000c98 <release>
}
    8000397a:	854a                	mv	a0,s2
    8000397c:	70a2                	ld	ra,40(sp)
    8000397e:	7402                	ld	s0,32(sp)
    80003980:	64e2                	ld	s1,24(sp)
    80003982:	6942                	ld	s2,16(sp)
    80003984:	69a2                	ld	s3,8(sp)
    80003986:	6a02                	ld	s4,0(sp)
    80003988:	6145                	addi	sp,sp,48
    8000398a:	8082                	ret
    panic("iget: no inodes");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	d1450513          	addi	a0,a0,-748 # 800086a0 <syscalls+0x148>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	baa080e7          	jalr	-1110(ra) # 8000053e <panic>

000000008000399c <fsinit>:
fsinit(int dev) {
    8000399c:	7179                	addi	sp,sp,-48
    8000399e:	f406                	sd	ra,40(sp)
    800039a0:	f022                	sd	s0,32(sp)
    800039a2:	ec26                	sd	s1,24(sp)
    800039a4:	e84a                	sd	s2,16(sp)
    800039a6:	e44e                	sd	s3,8(sp)
    800039a8:	1800                	addi	s0,sp,48
    800039aa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039ac:	4585                	li	a1,1
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	a64080e7          	jalr	-1436(ra) # 80003412 <bread>
    800039b6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039b8:	0001c997          	auipc	s3,0x1c
    800039bc:	61098993          	addi	s3,s3,1552 # 8001ffc8 <sb>
    800039c0:	02000613          	li	a2,32
    800039c4:	05850593          	addi	a1,a0,88
    800039c8:	854e                	mv	a0,s3
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	376080e7          	jalr	886(ra) # 80000d40 <memmove>
  brelse(bp);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	b6e080e7          	jalr	-1170(ra) # 80003542 <brelse>
  if(sb.magic != FSMAGIC)
    800039dc:	0009a703          	lw	a4,0(s3)
    800039e0:	102037b7          	lui	a5,0x10203
    800039e4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039e8:	02f71263          	bne	a4,a5,80003a0c <fsinit+0x70>
  initlog(dev, &sb);
    800039ec:	0001c597          	auipc	a1,0x1c
    800039f0:	5dc58593          	addi	a1,a1,1500 # 8001ffc8 <sb>
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	b4c080e7          	jalr	-1204(ra) # 80004542 <initlog>
}
    800039fe:	70a2                	ld	ra,40(sp)
    80003a00:	7402                	ld	s0,32(sp)
    80003a02:	64e2                	ld	s1,24(sp)
    80003a04:	6942                	ld	s2,16(sp)
    80003a06:	69a2                	ld	s3,8(sp)
    80003a08:	6145                	addi	sp,sp,48
    80003a0a:	8082                	ret
    panic("invalid file system");
    80003a0c:	00005517          	auipc	a0,0x5
    80003a10:	ca450513          	addi	a0,a0,-860 # 800086b0 <syscalls+0x158>
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	b2a080e7          	jalr	-1238(ra) # 8000053e <panic>

0000000080003a1c <iinit>:
{
    80003a1c:	7179                	addi	sp,sp,-48
    80003a1e:	f406                	sd	ra,40(sp)
    80003a20:	f022                	sd	s0,32(sp)
    80003a22:	ec26                	sd	s1,24(sp)
    80003a24:	e84a                	sd	s2,16(sp)
    80003a26:	e44e                	sd	s3,8(sp)
    80003a28:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a2a:	00005597          	auipc	a1,0x5
    80003a2e:	c9e58593          	addi	a1,a1,-866 # 800086c8 <syscalls+0x170>
    80003a32:	0001c517          	auipc	a0,0x1c
    80003a36:	5b650513          	addi	a0,a0,1462 # 8001ffe8 <itable>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	11a080e7          	jalr	282(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a42:	0001c497          	auipc	s1,0x1c
    80003a46:	5ce48493          	addi	s1,s1,1486 # 80020010 <itable+0x28>
    80003a4a:	0001e997          	auipc	s3,0x1e
    80003a4e:	05698993          	addi	s3,s3,86 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a52:	00005917          	auipc	s2,0x5
    80003a56:	c7e90913          	addi	s2,s2,-898 # 800086d0 <syscalls+0x178>
    80003a5a:	85ca                	mv	a1,s2
    80003a5c:	8526                	mv	a0,s1
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	e46080e7          	jalr	-442(ra) # 800048a4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a66:	08848493          	addi	s1,s1,136
    80003a6a:	ff3498e3          	bne	s1,s3,80003a5a <iinit+0x3e>
}
    80003a6e:	70a2                	ld	ra,40(sp)
    80003a70:	7402                	ld	s0,32(sp)
    80003a72:	64e2                	ld	s1,24(sp)
    80003a74:	6942                	ld	s2,16(sp)
    80003a76:	69a2                	ld	s3,8(sp)
    80003a78:	6145                	addi	sp,sp,48
    80003a7a:	8082                	ret

0000000080003a7c <ialloc>:
{
    80003a7c:	715d                	addi	sp,sp,-80
    80003a7e:	e486                	sd	ra,72(sp)
    80003a80:	e0a2                	sd	s0,64(sp)
    80003a82:	fc26                	sd	s1,56(sp)
    80003a84:	f84a                	sd	s2,48(sp)
    80003a86:	f44e                	sd	s3,40(sp)
    80003a88:	f052                	sd	s4,32(sp)
    80003a8a:	ec56                	sd	s5,24(sp)
    80003a8c:	e85a                	sd	s6,16(sp)
    80003a8e:	e45e                	sd	s7,8(sp)
    80003a90:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a92:	0001c717          	auipc	a4,0x1c
    80003a96:	54272703          	lw	a4,1346(a4) # 8001ffd4 <sb+0xc>
    80003a9a:	4785                	li	a5,1
    80003a9c:	04e7fa63          	bgeu	a5,a4,80003af0 <ialloc+0x74>
    80003aa0:	8aaa                	mv	s5,a0
    80003aa2:	8bae                	mv	s7,a1
    80003aa4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003aa6:	0001ca17          	auipc	s4,0x1c
    80003aaa:	522a0a13          	addi	s4,s4,1314 # 8001ffc8 <sb>
    80003aae:	00048b1b          	sext.w	s6,s1
    80003ab2:	0044d593          	srli	a1,s1,0x4
    80003ab6:	018a2783          	lw	a5,24(s4)
    80003aba:	9dbd                	addw	a1,a1,a5
    80003abc:	8556                	mv	a0,s5
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	954080e7          	jalr	-1708(ra) # 80003412 <bread>
    80003ac6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ac8:	05850993          	addi	s3,a0,88
    80003acc:	00f4f793          	andi	a5,s1,15
    80003ad0:	079a                	slli	a5,a5,0x6
    80003ad2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ad4:	00099783          	lh	a5,0(s3)
    80003ad8:	c785                	beqz	a5,80003b00 <ialloc+0x84>
    brelse(bp);
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	a68080e7          	jalr	-1432(ra) # 80003542 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ae2:	0485                	addi	s1,s1,1
    80003ae4:	00ca2703          	lw	a4,12(s4)
    80003ae8:	0004879b          	sext.w	a5,s1
    80003aec:	fce7e1e3          	bltu	a5,a4,80003aae <ialloc+0x32>
  panic("ialloc: no inodes");
    80003af0:	00005517          	auipc	a0,0x5
    80003af4:	be850513          	addi	a0,a0,-1048 # 800086d8 <syscalls+0x180>
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	a46080e7          	jalr	-1466(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003b00:	04000613          	li	a2,64
    80003b04:	4581                	li	a1,0
    80003b06:	854e                	mv	a0,s3
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	1d8080e7          	jalr	472(ra) # 80000ce0 <memset>
      dip->type = type;
    80003b10:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b14:	854a                	mv	a0,s2
    80003b16:	00001097          	auipc	ra,0x1
    80003b1a:	ca8080e7          	jalr	-856(ra) # 800047be <log_write>
      brelse(bp);
    80003b1e:	854a                	mv	a0,s2
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	a22080e7          	jalr	-1502(ra) # 80003542 <brelse>
      return iget(dev, inum);
    80003b28:	85da                	mv	a1,s6
    80003b2a:	8556                	mv	a0,s5
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	db4080e7          	jalr	-588(ra) # 800038e0 <iget>
}
    80003b34:	60a6                	ld	ra,72(sp)
    80003b36:	6406                	ld	s0,64(sp)
    80003b38:	74e2                	ld	s1,56(sp)
    80003b3a:	7942                	ld	s2,48(sp)
    80003b3c:	79a2                	ld	s3,40(sp)
    80003b3e:	7a02                	ld	s4,32(sp)
    80003b40:	6ae2                	ld	s5,24(sp)
    80003b42:	6b42                	ld	s6,16(sp)
    80003b44:	6ba2                	ld	s7,8(sp)
    80003b46:	6161                	addi	sp,sp,80
    80003b48:	8082                	ret

0000000080003b4a <iupdate>:
{
    80003b4a:	1101                	addi	sp,sp,-32
    80003b4c:	ec06                	sd	ra,24(sp)
    80003b4e:	e822                	sd	s0,16(sp)
    80003b50:	e426                	sd	s1,8(sp)
    80003b52:	e04a                	sd	s2,0(sp)
    80003b54:	1000                	addi	s0,sp,32
    80003b56:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b58:	415c                	lw	a5,4(a0)
    80003b5a:	0047d79b          	srliw	a5,a5,0x4
    80003b5e:	0001c597          	auipc	a1,0x1c
    80003b62:	4825a583          	lw	a1,1154(a1) # 8001ffe0 <sb+0x18>
    80003b66:	9dbd                	addw	a1,a1,a5
    80003b68:	4108                	lw	a0,0(a0)
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	8a8080e7          	jalr	-1880(ra) # 80003412 <bread>
    80003b72:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b74:	05850793          	addi	a5,a0,88
    80003b78:	40c8                	lw	a0,4(s1)
    80003b7a:	893d                	andi	a0,a0,15
    80003b7c:	051a                	slli	a0,a0,0x6
    80003b7e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003b80:	04449703          	lh	a4,68(s1)
    80003b84:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b88:	04649703          	lh	a4,70(s1)
    80003b8c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b90:	04849703          	lh	a4,72(s1)
    80003b94:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b98:	04a49703          	lh	a4,74(s1)
    80003b9c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ba0:	44f8                	lw	a4,76(s1)
    80003ba2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ba4:	03400613          	li	a2,52
    80003ba8:	05048593          	addi	a1,s1,80
    80003bac:	0531                	addi	a0,a0,12
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	192080e7          	jalr	402(ra) # 80000d40 <memmove>
  log_write(bp);
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	00001097          	auipc	ra,0x1
    80003bbc:	c06080e7          	jalr	-1018(ra) # 800047be <log_write>
  brelse(bp);
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	980080e7          	jalr	-1664(ra) # 80003542 <brelse>
}
    80003bca:	60e2                	ld	ra,24(sp)
    80003bcc:	6442                	ld	s0,16(sp)
    80003bce:	64a2                	ld	s1,8(sp)
    80003bd0:	6902                	ld	s2,0(sp)
    80003bd2:	6105                	addi	sp,sp,32
    80003bd4:	8082                	ret

0000000080003bd6 <idup>:
{
    80003bd6:	1101                	addi	sp,sp,-32
    80003bd8:	ec06                	sd	ra,24(sp)
    80003bda:	e822                	sd	s0,16(sp)
    80003bdc:	e426                	sd	s1,8(sp)
    80003bde:	1000                	addi	s0,sp,32
    80003be0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003be2:	0001c517          	auipc	a0,0x1c
    80003be6:	40650513          	addi	a0,a0,1030 # 8001ffe8 <itable>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	ffa080e7          	jalr	-6(ra) # 80000be4 <acquire>
  ip->ref++;
    80003bf2:	449c                	lw	a5,8(s1)
    80003bf4:	2785                	addiw	a5,a5,1
    80003bf6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bf8:	0001c517          	auipc	a0,0x1c
    80003bfc:	3f050513          	addi	a0,a0,1008 # 8001ffe8 <itable>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	098080e7          	jalr	152(ra) # 80000c98 <release>
}
    80003c08:	8526                	mv	a0,s1
    80003c0a:	60e2                	ld	ra,24(sp)
    80003c0c:	6442                	ld	s0,16(sp)
    80003c0e:	64a2                	ld	s1,8(sp)
    80003c10:	6105                	addi	sp,sp,32
    80003c12:	8082                	ret

0000000080003c14 <ilock>:
{
    80003c14:	1101                	addi	sp,sp,-32
    80003c16:	ec06                	sd	ra,24(sp)
    80003c18:	e822                	sd	s0,16(sp)
    80003c1a:	e426                	sd	s1,8(sp)
    80003c1c:	e04a                	sd	s2,0(sp)
    80003c1e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c20:	c115                	beqz	a0,80003c44 <ilock+0x30>
    80003c22:	84aa                	mv	s1,a0
    80003c24:	451c                	lw	a5,8(a0)
    80003c26:	00f05f63          	blez	a5,80003c44 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c2a:	0541                	addi	a0,a0,16
    80003c2c:	00001097          	auipc	ra,0x1
    80003c30:	cb2080e7          	jalr	-846(ra) # 800048de <acquiresleep>
  if(ip->valid == 0){
    80003c34:	40bc                	lw	a5,64(s1)
    80003c36:	cf99                	beqz	a5,80003c54 <ilock+0x40>
}
    80003c38:	60e2                	ld	ra,24(sp)
    80003c3a:	6442                	ld	s0,16(sp)
    80003c3c:	64a2                	ld	s1,8(sp)
    80003c3e:	6902                	ld	s2,0(sp)
    80003c40:	6105                	addi	sp,sp,32
    80003c42:	8082                	ret
    panic("ilock");
    80003c44:	00005517          	auipc	a0,0x5
    80003c48:	aac50513          	addi	a0,a0,-1364 # 800086f0 <syscalls+0x198>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	8f2080e7          	jalr	-1806(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c54:	40dc                	lw	a5,4(s1)
    80003c56:	0047d79b          	srliw	a5,a5,0x4
    80003c5a:	0001c597          	auipc	a1,0x1c
    80003c5e:	3865a583          	lw	a1,902(a1) # 8001ffe0 <sb+0x18>
    80003c62:	9dbd                	addw	a1,a1,a5
    80003c64:	4088                	lw	a0,0(s1)
    80003c66:	fffff097          	auipc	ra,0xfffff
    80003c6a:	7ac080e7          	jalr	1964(ra) # 80003412 <bread>
    80003c6e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c70:	05850593          	addi	a1,a0,88
    80003c74:	40dc                	lw	a5,4(s1)
    80003c76:	8bbd                	andi	a5,a5,15
    80003c78:	079a                	slli	a5,a5,0x6
    80003c7a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c7c:	00059783          	lh	a5,0(a1)
    80003c80:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c84:	00259783          	lh	a5,2(a1)
    80003c88:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c8c:	00459783          	lh	a5,4(a1)
    80003c90:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c94:	00659783          	lh	a5,6(a1)
    80003c98:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003c9c:	459c                	lw	a5,8(a1)
    80003c9e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ca0:	03400613          	li	a2,52
    80003ca4:	05b1                	addi	a1,a1,12
    80003ca6:	05048513          	addi	a0,s1,80
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	096080e7          	jalr	150(ra) # 80000d40 <memmove>
    brelse(bp);
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	88e080e7          	jalr	-1906(ra) # 80003542 <brelse>
    ip->valid = 1;
    80003cbc:	4785                	li	a5,1
    80003cbe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cc0:	04449783          	lh	a5,68(s1)
    80003cc4:	fbb5                	bnez	a5,80003c38 <ilock+0x24>
      panic("ilock: no type");
    80003cc6:	00005517          	auipc	a0,0x5
    80003cca:	a3250513          	addi	a0,a0,-1486 # 800086f8 <syscalls+0x1a0>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	870080e7          	jalr	-1936(ra) # 8000053e <panic>

0000000080003cd6 <iunlock>:
{
    80003cd6:	1101                	addi	sp,sp,-32
    80003cd8:	ec06                	sd	ra,24(sp)
    80003cda:	e822                	sd	s0,16(sp)
    80003cdc:	e426                	sd	s1,8(sp)
    80003cde:	e04a                	sd	s2,0(sp)
    80003ce0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ce2:	c905                	beqz	a0,80003d12 <iunlock+0x3c>
    80003ce4:	84aa                	mv	s1,a0
    80003ce6:	01050913          	addi	s2,a0,16
    80003cea:	854a                	mv	a0,s2
    80003cec:	00001097          	auipc	ra,0x1
    80003cf0:	c8c080e7          	jalr	-884(ra) # 80004978 <holdingsleep>
    80003cf4:	cd19                	beqz	a0,80003d12 <iunlock+0x3c>
    80003cf6:	449c                	lw	a5,8(s1)
    80003cf8:	00f05d63          	blez	a5,80003d12 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003cfc:	854a                	mv	a0,s2
    80003cfe:	00001097          	auipc	ra,0x1
    80003d02:	c36080e7          	jalr	-970(ra) # 80004934 <releasesleep>
}
    80003d06:	60e2                	ld	ra,24(sp)
    80003d08:	6442                	ld	s0,16(sp)
    80003d0a:	64a2                	ld	s1,8(sp)
    80003d0c:	6902                	ld	s2,0(sp)
    80003d0e:	6105                	addi	sp,sp,32
    80003d10:	8082                	ret
    panic("iunlock");
    80003d12:	00005517          	auipc	a0,0x5
    80003d16:	9f650513          	addi	a0,a0,-1546 # 80008708 <syscalls+0x1b0>
    80003d1a:	ffffd097          	auipc	ra,0xffffd
    80003d1e:	824080e7          	jalr	-2012(ra) # 8000053e <panic>

0000000080003d22 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d22:	7179                	addi	sp,sp,-48
    80003d24:	f406                	sd	ra,40(sp)
    80003d26:	f022                	sd	s0,32(sp)
    80003d28:	ec26                	sd	s1,24(sp)
    80003d2a:	e84a                	sd	s2,16(sp)
    80003d2c:	e44e                	sd	s3,8(sp)
    80003d2e:	e052                	sd	s4,0(sp)
    80003d30:	1800                	addi	s0,sp,48
    80003d32:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d34:	05050493          	addi	s1,a0,80
    80003d38:	08050913          	addi	s2,a0,128
    80003d3c:	a021                	j	80003d44 <itrunc+0x22>
    80003d3e:	0491                	addi	s1,s1,4
    80003d40:	01248d63          	beq	s1,s2,80003d5a <itrunc+0x38>
    if(ip->addrs[i]){
    80003d44:	408c                	lw	a1,0(s1)
    80003d46:	dde5                	beqz	a1,80003d3e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d48:	0009a503          	lw	a0,0(s3)
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	90c080e7          	jalr	-1780(ra) # 80003658 <bfree>
      ip->addrs[i] = 0;
    80003d54:	0004a023          	sw	zero,0(s1)
    80003d58:	b7dd                	j	80003d3e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d5a:	0809a583          	lw	a1,128(s3)
    80003d5e:	e185                	bnez	a1,80003d7e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d60:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d64:	854e                	mv	a0,s3
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	de4080e7          	jalr	-540(ra) # 80003b4a <iupdate>
}
    80003d6e:	70a2                	ld	ra,40(sp)
    80003d70:	7402                	ld	s0,32(sp)
    80003d72:	64e2                	ld	s1,24(sp)
    80003d74:	6942                	ld	s2,16(sp)
    80003d76:	69a2                	ld	s3,8(sp)
    80003d78:	6a02                	ld	s4,0(sp)
    80003d7a:	6145                	addi	sp,sp,48
    80003d7c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d7e:	0009a503          	lw	a0,0(s3)
    80003d82:	fffff097          	auipc	ra,0xfffff
    80003d86:	690080e7          	jalr	1680(ra) # 80003412 <bread>
    80003d8a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d8c:	05850493          	addi	s1,a0,88
    80003d90:	45850913          	addi	s2,a0,1112
    80003d94:	a811                	j	80003da8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d96:	0009a503          	lw	a0,0(s3)
    80003d9a:	00000097          	auipc	ra,0x0
    80003d9e:	8be080e7          	jalr	-1858(ra) # 80003658 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003da2:	0491                	addi	s1,s1,4
    80003da4:	01248563          	beq	s1,s2,80003dae <itrunc+0x8c>
      if(a[j])
    80003da8:	408c                	lw	a1,0(s1)
    80003daa:	dde5                	beqz	a1,80003da2 <itrunc+0x80>
    80003dac:	b7ed                	j	80003d96 <itrunc+0x74>
    brelse(bp);
    80003dae:	8552                	mv	a0,s4
    80003db0:	fffff097          	auipc	ra,0xfffff
    80003db4:	792080e7          	jalr	1938(ra) # 80003542 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003db8:	0809a583          	lw	a1,128(s3)
    80003dbc:	0009a503          	lw	a0,0(s3)
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	898080e7          	jalr	-1896(ra) # 80003658 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dc8:	0809a023          	sw	zero,128(s3)
    80003dcc:	bf51                	j	80003d60 <itrunc+0x3e>

0000000080003dce <iput>:
{
    80003dce:	1101                	addi	sp,sp,-32
    80003dd0:	ec06                	sd	ra,24(sp)
    80003dd2:	e822                	sd	s0,16(sp)
    80003dd4:	e426                	sd	s1,8(sp)
    80003dd6:	e04a                	sd	s2,0(sp)
    80003dd8:	1000                	addi	s0,sp,32
    80003dda:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ddc:	0001c517          	auipc	a0,0x1c
    80003de0:	20c50513          	addi	a0,a0,524 # 8001ffe8 <itable>
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	e00080e7          	jalr	-512(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003dec:	4498                	lw	a4,8(s1)
    80003dee:	4785                	li	a5,1
    80003df0:	02f70363          	beq	a4,a5,80003e16 <iput+0x48>
  ip->ref--;
    80003df4:	449c                	lw	a5,8(s1)
    80003df6:	37fd                	addiw	a5,a5,-1
    80003df8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dfa:	0001c517          	auipc	a0,0x1c
    80003dfe:	1ee50513          	addi	a0,a0,494 # 8001ffe8 <itable>
    80003e02:	ffffd097          	auipc	ra,0xffffd
    80003e06:	e96080e7          	jalr	-362(ra) # 80000c98 <release>
}
    80003e0a:	60e2                	ld	ra,24(sp)
    80003e0c:	6442                	ld	s0,16(sp)
    80003e0e:	64a2                	ld	s1,8(sp)
    80003e10:	6902                	ld	s2,0(sp)
    80003e12:	6105                	addi	sp,sp,32
    80003e14:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e16:	40bc                	lw	a5,64(s1)
    80003e18:	dff1                	beqz	a5,80003df4 <iput+0x26>
    80003e1a:	04a49783          	lh	a5,74(s1)
    80003e1e:	fbf9                	bnez	a5,80003df4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003e20:	01048913          	addi	s2,s1,16
    80003e24:	854a                	mv	a0,s2
    80003e26:	00001097          	auipc	ra,0x1
    80003e2a:	ab8080e7          	jalr	-1352(ra) # 800048de <acquiresleep>
    release(&itable.lock);
    80003e2e:	0001c517          	auipc	a0,0x1c
    80003e32:	1ba50513          	addi	a0,a0,442 # 8001ffe8 <itable>
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	e62080e7          	jalr	-414(ra) # 80000c98 <release>
    itrunc(ip);
    80003e3e:	8526                	mv	a0,s1
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	ee2080e7          	jalr	-286(ra) # 80003d22 <itrunc>
    ip->type = 0;
    80003e48:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e4c:	8526                	mv	a0,s1
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	cfc080e7          	jalr	-772(ra) # 80003b4a <iupdate>
    ip->valid = 0;
    80003e56:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	00001097          	auipc	ra,0x1
    80003e60:	ad8080e7          	jalr	-1320(ra) # 80004934 <releasesleep>
    acquire(&itable.lock);
    80003e64:	0001c517          	auipc	a0,0x1c
    80003e68:	18450513          	addi	a0,a0,388 # 8001ffe8 <itable>
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	d78080e7          	jalr	-648(ra) # 80000be4 <acquire>
    80003e74:	b741                	j	80003df4 <iput+0x26>

0000000080003e76 <iunlockput>:
{
    80003e76:	1101                	addi	sp,sp,-32
    80003e78:	ec06                	sd	ra,24(sp)
    80003e7a:	e822                	sd	s0,16(sp)
    80003e7c:	e426                	sd	s1,8(sp)
    80003e7e:	1000                	addi	s0,sp,32
    80003e80:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	e54080e7          	jalr	-428(ra) # 80003cd6 <iunlock>
  iput(ip);
    80003e8a:	8526                	mv	a0,s1
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	f42080e7          	jalr	-190(ra) # 80003dce <iput>
}
    80003e94:	60e2                	ld	ra,24(sp)
    80003e96:	6442                	ld	s0,16(sp)
    80003e98:	64a2                	ld	s1,8(sp)
    80003e9a:	6105                	addi	sp,sp,32
    80003e9c:	8082                	ret

0000000080003e9e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e9e:	1141                	addi	sp,sp,-16
    80003ea0:	e422                	sd	s0,8(sp)
    80003ea2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ea4:	411c                	lw	a5,0(a0)
    80003ea6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ea8:	415c                	lw	a5,4(a0)
    80003eaa:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003eac:	04451783          	lh	a5,68(a0)
    80003eb0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003eb4:	04a51783          	lh	a5,74(a0)
    80003eb8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ebc:	04c56783          	lwu	a5,76(a0)
    80003ec0:	e99c                	sd	a5,16(a1)
}
    80003ec2:	6422                	ld	s0,8(sp)
    80003ec4:	0141                	addi	sp,sp,16
    80003ec6:	8082                	ret

0000000080003ec8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ec8:	457c                	lw	a5,76(a0)
    80003eca:	0ed7e963          	bltu	a5,a3,80003fbc <readi+0xf4>
{
    80003ece:	7159                	addi	sp,sp,-112
    80003ed0:	f486                	sd	ra,104(sp)
    80003ed2:	f0a2                	sd	s0,96(sp)
    80003ed4:	eca6                	sd	s1,88(sp)
    80003ed6:	e8ca                	sd	s2,80(sp)
    80003ed8:	e4ce                	sd	s3,72(sp)
    80003eda:	e0d2                	sd	s4,64(sp)
    80003edc:	fc56                	sd	s5,56(sp)
    80003ede:	f85a                	sd	s6,48(sp)
    80003ee0:	f45e                	sd	s7,40(sp)
    80003ee2:	f062                	sd	s8,32(sp)
    80003ee4:	ec66                	sd	s9,24(sp)
    80003ee6:	e86a                	sd	s10,16(sp)
    80003ee8:	e46e                	sd	s11,8(sp)
    80003eea:	1880                	addi	s0,sp,112
    80003eec:	8baa                	mv	s7,a0
    80003eee:	8c2e                	mv	s8,a1
    80003ef0:	8ab2                	mv	s5,a2
    80003ef2:	84b6                	mv	s1,a3
    80003ef4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ef6:	9f35                	addw	a4,a4,a3
    return 0;
    80003ef8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003efa:	0ad76063          	bltu	a4,a3,80003f9a <readi+0xd2>
  if(off + n > ip->size)
    80003efe:	00e7f463          	bgeu	a5,a4,80003f06 <readi+0x3e>
    n = ip->size - off;
    80003f02:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f06:	0a0b0963          	beqz	s6,80003fb8 <readi+0xf0>
    80003f0a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f0c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f10:	5cfd                	li	s9,-1
    80003f12:	a82d                	j	80003f4c <readi+0x84>
    80003f14:	020a1d93          	slli	s11,s4,0x20
    80003f18:	020ddd93          	srli	s11,s11,0x20
    80003f1c:	05890613          	addi	a2,s2,88
    80003f20:	86ee                	mv	a3,s11
    80003f22:	963a                	add	a2,a2,a4
    80003f24:	85d6                	mv	a1,s5
    80003f26:	8562                	mv	a0,s8
    80003f28:	ffffe097          	auipc	ra,0xffffe
    80003f2c:	53c080e7          	jalr	1340(ra) # 80002464 <either_copyout>
    80003f30:	05950d63          	beq	a0,s9,80003f8a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f34:	854a                	mv	a0,s2
    80003f36:	fffff097          	auipc	ra,0xfffff
    80003f3a:	60c080e7          	jalr	1548(ra) # 80003542 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f3e:	013a09bb          	addw	s3,s4,s3
    80003f42:	009a04bb          	addw	s1,s4,s1
    80003f46:	9aee                	add	s5,s5,s11
    80003f48:	0569f763          	bgeu	s3,s6,80003f96 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003f4c:	000ba903          	lw	s2,0(s7)
    80003f50:	00a4d59b          	srliw	a1,s1,0xa
    80003f54:	855e                	mv	a0,s7
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	8b0080e7          	jalr	-1872(ra) # 80003806 <bmap>
    80003f5e:	0005059b          	sext.w	a1,a0
    80003f62:	854a                	mv	a0,s2
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	4ae080e7          	jalr	1198(ra) # 80003412 <bread>
    80003f6c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f6e:	3ff4f713          	andi	a4,s1,1023
    80003f72:	40ed07bb          	subw	a5,s10,a4
    80003f76:	413b06bb          	subw	a3,s6,s3
    80003f7a:	8a3e                	mv	s4,a5
    80003f7c:	2781                	sext.w	a5,a5
    80003f7e:	0006861b          	sext.w	a2,a3
    80003f82:	f8f679e3          	bgeu	a2,a5,80003f14 <readi+0x4c>
    80003f86:	8a36                	mv	s4,a3
    80003f88:	b771                	j	80003f14 <readi+0x4c>
      brelse(bp);
    80003f8a:	854a                	mv	a0,s2
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	5b6080e7          	jalr	1462(ra) # 80003542 <brelse>
      tot = -1;
    80003f94:	59fd                	li	s3,-1
  }
  return tot;
    80003f96:	0009851b          	sext.w	a0,s3
}
    80003f9a:	70a6                	ld	ra,104(sp)
    80003f9c:	7406                	ld	s0,96(sp)
    80003f9e:	64e6                	ld	s1,88(sp)
    80003fa0:	6946                	ld	s2,80(sp)
    80003fa2:	69a6                	ld	s3,72(sp)
    80003fa4:	6a06                	ld	s4,64(sp)
    80003fa6:	7ae2                	ld	s5,56(sp)
    80003fa8:	7b42                	ld	s6,48(sp)
    80003faa:	7ba2                	ld	s7,40(sp)
    80003fac:	7c02                	ld	s8,32(sp)
    80003fae:	6ce2                	ld	s9,24(sp)
    80003fb0:	6d42                	ld	s10,16(sp)
    80003fb2:	6da2                	ld	s11,8(sp)
    80003fb4:	6165                	addi	sp,sp,112
    80003fb6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fb8:	89da                	mv	s3,s6
    80003fba:	bff1                	j	80003f96 <readi+0xce>
    return 0;
    80003fbc:	4501                	li	a0,0
}
    80003fbe:	8082                	ret

0000000080003fc0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc0:	457c                	lw	a5,76(a0)
    80003fc2:	10d7e863          	bltu	a5,a3,800040d2 <writei+0x112>
{
    80003fc6:	7159                	addi	sp,sp,-112
    80003fc8:	f486                	sd	ra,104(sp)
    80003fca:	f0a2                	sd	s0,96(sp)
    80003fcc:	eca6                	sd	s1,88(sp)
    80003fce:	e8ca                	sd	s2,80(sp)
    80003fd0:	e4ce                	sd	s3,72(sp)
    80003fd2:	e0d2                	sd	s4,64(sp)
    80003fd4:	fc56                	sd	s5,56(sp)
    80003fd6:	f85a                	sd	s6,48(sp)
    80003fd8:	f45e                	sd	s7,40(sp)
    80003fda:	f062                	sd	s8,32(sp)
    80003fdc:	ec66                	sd	s9,24(sp)
    80003fde:	e86a                	sd	s10,16(sp)
    80003fe0:	e46e                	sd	s11,8(sp)
    80003fe2:	1880                	addi	s0,sp,112
    80003fe4:	8b2a                	mv	s6,a0
    80003fe6:	8c2e                	mv	s8,a1
    80003fe8:	8ab2                	mv	s5,a2
    80003fea:	8936                	mv	s2,a3
    80003fec:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003fee:	00e687bb          	addw	a5,a3,a4
    80003ff2:	0ed7e263          	bltu	a5,a3,800040d6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ff6:	00043737          	lui	a4,0x43
    80003ffa:	0ef76063          	bltu	a4,a5,800040da <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ffe:	0c0b8863          	beqz	s7,800040ce <writei+0x10e>
    80004002:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004004:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004008:	5cfd                	li	s9,-1
    8000400a:	a091                	j	8000404e <writei+0x8e>
    8000400c:	02099d93          	slli	s11,s3,0x20
    80004010:	020ddd93          	srli	s11,s11,0x20
    80004014:	05848513          	addi	a0,s1,88
    80004018:	86ee                	mv	a3,s11
    8000401a:	8656                	mv	a2,s5
    8000401c:	85e2                	mv	a1,s8
    8000401e:	953a                	add	a0,a0,a4
    80004020:	ffffe097          	auipc	ra,0xffffe
    80004024:	49a080e7          	jalr	1178(ra) # 800024ba <either_copyin>
    80004028:	07950263          	beq	a0,s9,8000408c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000402c:	8526                	mv	a0,s1
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	790080e7          	jalr	1936(ra) # 800047be <log_write>
    brelse(bp);
    80004036:	8526                	mv	a0,s1
    80004038:	fffff097          	auipc	ra,0xfffff
    8000403c:	50a080e7          	jalr	1290(ra) # 80003542 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004040:	01498a3b          	addw	s4,s3,s4
    80004044:	0129893b          	addw	s2,s3,s2
    80004048:	9aee                	add	s5,s5,s11
    8000404a:	057a7663          	bgeu	s4,s7,80004096 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000404e:	000b2483          	lw	s1,0(s6)
    80004052:	00a9559b          	srliw	a1,s2,0xa
    80004056:	855a                	mv	a0,s6
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	7ae080e7          	jalr	1966(ra) # 80003806 <bmap>
    80004060:	0005059b          	sext.w	a1,a0
    80004064:	8526                	mv	a0,s1
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	3ac080e7          	jalr	940(ra) # 80003412 <bread>
    8000406e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004070:	3ff97713          	andi	a4,s2,1023
    80004074:	40ed07bb          	subw	a5,s10,a4
    80004078:	414b86bb          	subw	a3,s7,s4
    8000407c:	89be                	mv	s3,a5
    8000407e:	2781                	sext.w	a5,a5
    80004080:	0006861b          	sext.w	a2,a3
    80004084:	f8f674e3          	bgeu	a2,a5,8000400c <writei+0x4c>
    80004088:	89b6                	mv	s3,a3
    8000408a:	b749                	j	8000400c <writei+0x4c>
      brelse(bp);
    8000408c:	8526                	mv	a0,s1
    8000408e:	fffff097          	auipc	ra,0xfffff
    80004092:	4b4080e7          	jalr	1204(ra) # 80003542 <brelse>
  }

  if(off > ip->size)
    80004096:	04cb2783          	lw	a5,76(s6)
    8000409a:	0127f463          	bgeu	a5,s2,800040a2 <writei+0xe2>
    ip->size = off;
    8000409e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040a2:	855a                	mv	a0,s6
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	aa6080e7          	jalr	-1370(ra) # 80003b4a <iupdate>

  return tot;
    800040ac:	000a051b          	sext.w	a0,s4
}
    800040b0:	70a6                	ld	ra,104(sp)
    800040b2:	7406                	ld	s0,96(sp)
    800040b4:	64e6                	ld	s1,88(sp)
    800040b6:	6946                	ld	s2,80(sp)
    800040b8:	69a6                	ld	s3,72(sp)
    800040ba:	6a06                	ld	s4,64(sp)
    800040bc:	7ae2                	ld	s5,56(sp)
    800040be:	7b42                	ld	s6,48(sp)
    800040c0:	7ba2                	ld	s7,40(sp)
    800040c2:	7c02                	ld	s8,32(sp)
    800040c4:	6ce2                	ld	s9,24(sp)
    800040c6:	6d42                	ld	s10,16(sp)
    800040c8:	6da2                	ld	s11,8(sp)
    800040ca:	6165                	addi	sp,sp,112
    800040cc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040ce:	8a5e                	mv	s4,s7
    800040d0:	bfc9                	j	800040a2 <writei+0xe2>
    return -1;
    800040d2:	557d                	li	a0,-1
}
    800040d4:	8082                	ret
    return -1;
    800040d6:	557d                	li	a0,-1
    800040d8:	bfe1                	j	800040b0 <writei+0xf0>
    return -1;
    800040da:	557d                	li	a0,-1
    800040dc:	bfd1                	j	800040b0 <writei+0xf0>

00000000800040de <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040de:	1141                	addi	sp,sp,-16
    800040e0:	e406                	sd	ra,8(sp)
    800040e2:	e022                	sd	s0,0(sp)
    800040e4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040e6:	4639                	li	a2,14
    800040e8:	ffffd097          	auipc	ra,0xffffd
    800040ec:	cd0080e7          	jalr	-816(ra) # 80000db8 <strncmp>
}
    800040f0:	60a2                	ld	ra,8(sp)
    800040f2:	6402                	ld	s0,0(sp)
    800040f4:	0141                	addi	sp,sp,16
    800040f6:	8082                	ret

00000000800040f8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040f8:	7139                	addi	sp,sp,-64
    800040fa:	fc06                	sd	ra,56(sp)
    800040fc:	f822                	sd	s0,48(sp)
    800040fe:	f426                	sd	s1,40(sp)
    80004100:	f04a                	sd	s2,32(sp)
    80004102:	ec4e                	sd	s3,24(sp)
    80004104:	e852                	sd	s4,16(sp)
    80004106:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004108:	04451703          	lh	a4,68(a0)
    8000410c:	4785                	li	a5,1
    8000410e:	00f71a63          	bne	a4,a5,80004122 <dirlookup+0x2a>
    80004112:	892a                	mv	s2,a0
    80004114:	89ae                	mv	s3,a1
    80004116:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004118:	457c                	lw	a5,76(a0)
    8000411a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000411c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000411e:	e79d                	bnez	a5,8000414c <dirlookup+0x54>
    80004120:	a8a5                	j	80004198 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004122:	00004517          	auipc	a0,0x4
    80004126:	5ee50513          	addi	a0,a0,1518 # 80008710 <syscalls+0x1b8>
    8000412a:	ffffc097          	auipc	ra,0xffffc
    8000412e:	414080e7          	jalr	1044(ra) # 8000053e <panic>
      panic("dirlookup read");
    80004132:	00004517          	auipc	a0,0x4
    80004136:	5f650513          	addi	a0,a0,1526 # 80008728 <syscalls+0x1d0>
    8000413a:	ffffc097          	auipc	ra,0xffffc
    8000413e:	404080e7          	jalr	1028(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004142:	24c1                	addiw	s1,s1,16
    80004144:	04c92783          	lw	a5,76(s2)
    80004148:	04f4f763          	bgeu	s1,a5,80004196 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000414c:	4741                	li	a4,16
    8000414e:	86a6                	mv	a3,s1
    80004150:	fc040613          	addi	a2,s0,-64
    80004154:	4581                	li	a1,0
    80004156:	854a                	mv	a0,s2
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	d70080e7          	jalr	-656(ra) # 80003ec8 <readi>
    80004160:	47c1                	li	a5,16
    80004162:	fcf518e3          	bne	a0,a5,80004132 <dirlookup+0x3a>
    if(de.inum == 0)
    80004166:	fc045783          	lhu	a5,-64(s0)
    8000416a:	dfe1                	beqz	a5,80004142 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000416c:	fc240593          	addi	a1,s0,-62
    80004170:	854e                	mv	a0,s3
    80004172:	00000097          	auipc	ra,0x0
    80004176:	f6c080e7          	jalr	-148(ra) # 800040de <namecmp>
    8000417a:	f561                	bnez	a0,80004142 <dirlookup+0x4a>
      if(poff)
    8000417c:	000a0463          	beqz	s4,80004184 <dirlookup+0x8c>
        *poff = off;
    80004180:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004184:	fc045583          	lhu	a1,-64(s0)
    80004188:	00092503          	lw	a0,0(s2)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	754080e7          	jalr	1876(ra) # 800038e0 <iget>
    80004194:	a011                	j	80004198 <dirlookup+0xa0>
  return 0;
    80004196:	4501                	li	a0,0
}
    80004198:	70e2                	ld	ra,56(sp)
    8000419a:	7442                	ld	s0,48(sp)
    8000419c:	74a2                	ld	s1,40(sp)
    8000419e:	7902                	ld	s2,32(sp)
    800041a0:	69e2                	ld	s3,24(sp)
    800041a2:	6a42                	ld	s4,16(sp)
    800041a4:	6121                	addi	sp,sp,64
    800041a6:	8082                	ret

00000000800041a8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041a8:	711d                	addi	sp,sp,-96
    800041aa:	ec86                	sd	ra,88(sp)
    800041ac:	e8a2                	sd	s0,80(sp)
    800041ae:	e4a6                	sd	s1,72(sp)
    800041b0:	e0ca                	sd	s2,64(sp)
    800041b2:	fc4e                	sd	s3,56(sp)
    800041b4:	f852                	sd	s4,48(sp)
    800041b6:	f456                	sd	s5,40(sp)
    800041b8:	f05a                	sd	s6,32(sp)
    800041ba:	ec5e                	sd	s7,24(sp)
    800041bc:	e862                	sd	s8,16(sp)
    800041be:	e466                	sd	s9,8(sp)
    800041c0:	1080                	addi	s0,sp,96
    800041c2:	84aa                	mv	s1,a0
    800041c4:	8b2e                	mv	s6,a1
    800041c6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041c8:	00054703          	lbu	a4,0(a0)
    800041cc:	02f00793          	li	a5,47
    800041d0:	02f70363          	beq	a4,a5,800041f6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	7dc080e7          	jalr	2012(ra) # 800019b0 <myproc>
    800041dc:	17053503          	ld	a0,368(a0)
    800041e0:	00000097          	auipc	ra,0x0
    800041e4:	9f6080e7          	jalr	-1546(ra) # 80003bd6 <idup>
    800041e8:	89aa                	mv	s3,a0
  while(*path == '/')
    800041ea:	02f00913          	li	s2,47
  len = path - s;
    800041ee:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800041f0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041f2:	4c05                	li	s8,1
    800041f4:	a865                	j	800042ac <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800041f6:	4585                	li	a1,1
    800041f8:	4505                	li	a0,1
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	6e6080e7          	jalr	1766(ra) # 800038e0 <iget>
    80004202:	89aa                	mv	s3,a0
    80004204:	b7dd                	j	800041ea <namex+0x42>
      iunlockput(ip);
    80004206:	854e                	mv	a0,s3
    80004208:	00000097          	auipc	ra,0x0
    8000420c:	c6e080e7          	jalr	-914(ra) # 80003e76 <iunlockput>
      return 0;
    80004210:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004212:	854e                	mv	a0,s3
    80004214:	60e6                	ld	ra,88(sp)
    80004216:	6446                	ld	s0,80(sp)
    80004218:	64a6                	ld	s1,72(sp)
    8000421a:	6906                	ld	s2,64(sp)
    8000421c:	79e2                	ld	s3,56(sp)
    8000421e:	7a42                	ld	s4,48(sp)
    80004220:	7aa2                	ld	s5,40(sp)
    80004222:	7b02                	ld	s6,32(sp)
    80004224:	6be2                	ld	s7,24(sp)
    80004226:	6c42                	ld	s8,16(sp)
    80004228:	6ca2                	ld	s9,8(sp)
    8000422a:	6125                	addi	sp,sp,96
    8000422c:	8082                	ret
      iunlock(ip);
    8000422e:	854e                	mv	a0,s3
    80004230:	00000097          	auipc	ra,0x0
    80004234:	aa6080e7          	jalr	-1370(ra) # 80003cd6 <iunlock>
      return ip;
    80004238:	bfe9                	j	80004212 <namex+0x6a>
      iunlockput(ip);
    8000423a:	854e                	mv	a0,s3
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	c3a080e7          	jalr	-966(ra) # 80003e76 <iunlockput>
      return 0;
    80004244:	89d2                	mv	s3,s4
    80004246:	b7f1                	j	80004212 <namex+0x6a>
  len = path - s;
    80004248:	40b48633          	sub	a2,s1,a1
    8000424c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004250:	094cd463          	bge	s9,s4,800042d8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004254:	4639                	li	a2,14
    80004256:	8556                	mv	a0,s5
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	ae8080e7          	jalr	-1304(ra) # 80000d40 <memmove>
  while(*path == '/')
    80004260:	0004c783          	lbu	a5,0(s1)
    80004264:	01279763          	bne	a5,s2,80004272 <namex+0xca>
    path++;
    80004268:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000426a:	0004c783          	lbu	a5,0(s1)
    8000426e:	ff278de3          	beq	a5,s2,80004268 <namex+0xc0>
    ilock(ip);
    80004272:	854e                	mv	a0,s3
    80004274:	00000097          	auipc	ra,0x0
    80004278:	9a0080e7          	jalr	-1632(ra) # 80003c14 <ilock>
    if(ip->type != T_DIR){
    8000427c:	04499783          	lh	a5,68(s3)
    80004280:	f98793e3          	bne	a5,s8,80004206 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004284:	000b0563          	beqz	s6,8000428e <namex+0xe6>
    80004288:	0004c783          	lbu	a5,0(s1)
    8000428c:	d3cd                	beqz	a5,8000422e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000428e:	865e                	mv	a2,s7
    80004290:	85d6                	mv	a1,s5
    80004292:	854e                	mv	a0,s3
    80004294:	00000097          	auipc	ra,0x0
    80004298:	e64080e7          	jalr	-412(ra) # 800040f8 <dirlookup>
    8000429c:	8a2a                	mv	s4,a0
    8000429e:	dd51                	beqz	a0,8000423a <namex+0x92>
    iunlockput(ip);
    800042a0:	854e                	mv	a0,s3
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	bd4080e7          	jalr	-1068(ra) # 80003e76 <iunlockput>
    ip = next;
    800042aa:	89d2                	mv	s3,s4
  while(*path == '/')
    800042ac:	0004c783          	lbu	a5,0(s1)
    800042b0:	05279763          	bne	a5,s2,800042fe <namex+0x156>
    path++;
    800042b4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042b6:	0004c783          	lbu	a5,0(s1)
    800042ba:	ff278de3          	beq	a5,s2,800042b4 <namex+0x10c>
  if(*path == 0)
    800042be:	c79d                	beqz	a5,800042ec <namex+0x144>
    path++;
    800042c0:	85a6                	mv	a1,s1
  len = path - s;
    800042c2:	8a5e                	mv	s4,s7
    800042c4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042c6:	01278963          	beq	a5,s2,800042d8 <namex+0x130>
    800042ca:	dfbd                	beqz	a5,80004248 <namex+0xa0>
    path++;
    800042cc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800042ce:	0004c783          	lbu	a5,0(s1)
    800042d2:	ff279ce3          	bne	a5,s2,800042ca <namex+0x122>
    800042d6:	bf8d                	j	80004248 <namex+0xa0>
    memmove(name, s, len);
    800042d8:	2601                	sext.w	a2,a2
    800042da:	8556                	mv	a0,s5
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	a64080e7          	jalr	-1436(ra) # 80000d40 <memmove>
    name[len] = 0;
    800042e4:	9a56                	add	s4,s4,s5
    800042e6:	000a0023          	sb	zero,0(s4)
    800042ea:	bf9d                	j	80004260 <namex+0xb8>
  if(nameiparent){
    800042ec:	f20b03e3          	beqz	s6,80004212 <namex+0x6a>
    iput(ip);
    800042f0:	854e                	mv	a0,s3
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	adc080e7          	jalr	-1316(ra) # 80003dce <iput>
    return 0;
    800042fa:	4981                	li	s3,0
    800042fc:	bf19                	j	80004212 <namex+0x6a>
  if(*path == 0)
    800042fe:	d7fd                	beqz	a5,800042ec <namex+0x144>
  while(*path != '/' && *path != 0)
    80004300:	0004c783          	lbu	a5,0(s1)
    80004304:	85a6                	mv	a1,s1
    80004306:	b7d1                	j	800042ca <namex+0x122>

0000000080004308 <dirlink>:
{
    80004308:	7139                	addi	sp,sp,-64
    8000430a:	fc06                	sd	ra,56(sp)
    8000430c:	f822                	sd	s0,48(sp)
    8000430e:	f426                	sd	s1,40(sp)
    80004310:	f04a                	sd	s2,32(sp)
    80004312:	ec4e                	sd	s3,24(sp)
    80004314:	e852                	sd	s4,16(sp)
    80004316:	0080                	addi	s0,sp,64
    80004318:	892a                	mv	s2,a0
    8000431a:	8a2e                	mv	s4,a1
    8000431c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000431e:	4601                	li	a2,0
    80004320:	00000097          	auipc	ra,0x0
    80004324:	dd8080e7          	jalr	-552(ra) # 800040f8 <dirlookup>
    80004328:	e93d                	bnez	a0,8000439e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000432a:	04c92483          	lw	s1,76(s2)
    8000432e:	c49d                	beqz	s1,8000435c <dirlink+0x54>
    80004330:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004332:	4741                	li	a4,16
    80004334:	86a6                	mv	a3,s1
    80004336:	fc040613          	addi	a2,s0,-64
    8000433a:	4581                	li	a1,0
    8000433c:	854a                	mv	a0,s2
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	b8a080e7          	jalr	-1142(ra) # 80003ec8 <readi>
    80004346:	47c1                	li	a5,16
    80004348:	06f51163          	bne	a0,a5,800043aa <dirlink+0xa2>
    if(de.inum == 0)
    8000434c:	fc045783          	lhu	a5,-64(s0)
    80004350:	c791                	beqz	a5,8000435c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004352:	24c1                	addiw	s1,s1,16
    80004354:	04c92783          	lw	a5,76(s2)
    80004358:	fcf4ede3          	bltu	s1,a5,80004332 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000435c:	4639                	li	a2,14
    8000435e:	85d2                	mv	a1,s4
    80004360:	fc240513          	addi	a0,s0,-62
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	a90080e7          	jalr	-1392(ra) # 80000df4 <strncpy>
  de.inum = inum;
    8000436c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004370:	4741                	li	a4,16
    80004372:	86a6                	mv	a3,s1
    80004374:	fc040613          	addi	a2,s0,-64
    80004378:	4581                	li	a1,0
    8000437a:	854a                	mv	a0,s2
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	c44080e7          	jalr	-956(ra) # 80003fc0 <writei>
    80004384:	872a                	mv	a4,a0
    80004386:	47c1                	li	a5,16
  return 0;
    80004388:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000438a:	02f71863          	bne	a4,a5,800043ba <dirlink+0xb2>
}
    8000438e:	70e2                	ld	ra,56(sp)
    80004390:	7442                	ld	s0,48(sp)
    80004392:	74a2                	ld	s1,40(sp)
    80004394:	7902                	ld	s2,32(sp)
    80004396:	69e2                	ld	s3,24(sp)
    80004398:	6a42                	ld	s4,16(sp)
    8000439a:	6121                	addi	sp,sp,64
    8000439c:	8082                	ret
    iput(ip);
    8000439e:	00000097          	auipc	ra,0x0
    800043a2:	a30080e7          	jalr	-1488(ra) # 80003dce <iput>
    return -1;
    800043a6:	557d                	li	a0,-1
    800043a8:	b7dd                	j	8000438e <dirlink+0x86>
      panic("dirlink read");
    800043aa:	00004517          	auipc	a0,0x4
    800043ae:	38e50513          	addi	a0,a0,910 # 80008738 <syscalls+0x1e0>
    800043b2:	ffffc097          	auipc	ra,0xffffc
    800043b6:	18c080e7          	jalr	396(ra) # 8000053e <panic>
    panic("dirlink");
    800043ba:	00004517          	auipc	a0,0x4
    800043be:	48e50513          	addi	a0,a0,1166 # 80008848 <syscalls+0x2f0>
    800043c2:	ffffc097          	auipc	ra,0xffffc
    800043c6:	17c080e7          	jalr	380(ra) # 8000053e <panic>

00000000800043ca <namei>:

struct inode*
namei(char *path)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043d2:	fe040613          	addi	a2,s0,-32
    800043d6:	4581                	li	a1,0
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	dd0080e7          	jalr	-560(ra) # 800041a8 <namex>
}
    800043e0:	60e2                	ld	ra,24(sp)
    800043e2:	6442                	ld	s0,16(sp)
    800043e4:	6105                	addi	sp,sp,32
    800043e6:	8082                	ret

00000000800043e8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043e8:	1141                	addi	sp,sp,-16
    800043ea:	e406                	sd	ra,8(sp)
    800043ec:	e022                	sd	s0,0(sp)
    800043ee:	0800                	addi	s0,sp,16
    800043f0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043f2:	4585                	li	a1,1
    800043f4:	00000097          	auipc	ra,0x0
    800043f8:	db4080e7          	jalr	-588(ra) # 800041a8 <namex>
}
    800043fc:	60a2                	ld	ra,8(sp)
    800043fe:	6402                	ld	s0,0(sp)
    80004400:	0141                	addi	sp,sp,16
    80004402:	8082                	ret

0000000080004404 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004404:	1101                	addi	sp,sp,-32
    80004406:	ec06                	sd	ra,24(sp)
    80004408:	e822                	sd	s0,16(sp)
    8000440a:	e426                	sd	s1,8(sp)
    8000440c:	e04a                	sd	s2,0(sp)
    8000440e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004410:	0001d917          	auipc	s2,0x1d
    80004414:	68090913          	addi	s2,s2,1664 # 80021a90 <log>
    80004418:	01892583          	lw	a1,24(s2)
    8000441c:	02892503          	lw	a0,40(s2)
    80004420:	fffff097          	auipc	ra,0xfffff
    80004424:	ff2080e7          	jalr	-14(ra) # 80003412 <bread>
    80004428:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000442a:	02c92683          	lw	a3,44(s2)
    8000442e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004430:	02d05763          	blez	a3,8000445e <write_head+0x5a>
    80004434:	0001d797          	auipc	a5,0x1d
    80004438:	68c78793          	addi	a5,a5,1676 # 80021ac0 <log+0x30>
    8000443c:	05c50713          	addi	a4,a0,92
    80004440:	36fd                	addiw	a3,a3,-1
    80004442:	1682                	slli	a3,a3,0x20
    80004444:	9281                	srli	a3,a3,0x20
    80004446:	068a                	slli	a3,a3,0x2
    80004448:	0001d617          	auipc	a2,0x1d
    8000444c:	67c60613          	addi	a2,a2,1660 # 80021ac4 <log+0x34>
    80004450:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004452:	4390                	lw	a2,0(a5)
    80004454:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004456:	0791                	addi	a5,a5,4
    80004458:	0711                	addi	a4,a4,4
    8000445a:	fed79ce3          	bne	a5,a3,80004452 <write_head+0x4e>
  }
  bwrite(buf);
    8000445e:	8526                	mv	a0,s1
    80004460:	fffff097          	auipc	ra,0xfffff
    80004464:	0a4080e7          	jalr	164(ra) # 80003504 <bwrite>
  brelse(buf);
    80004468:	8526                	mv	a0,s1
    8000446a:	fffff097          	auipc	ra,0xfffff
    8000446e:	0d8080e7          	jalr	216(ra) # 80003542 <brelse>
}
    80004472:	60e2                	ld	ra,24(sp)
    80004474:	6442                	ld	s0,16(sp)
    80004476:	64a2                	ld	s1,8(sp)
    80004478:	6902                	ld	s2,0(sp)
    8000447a:	6105                	addi	sp,sp,32
    8000447c:	8082                	ret

000000008000447e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447e:	0001d797          	auipc	a5,0x1d
    80004482:	63e7a783          	lw	a5,1598(a5) # 80021abc <log+0x2c>
    80004486:	0af05d63          	blez	a5,80004540 <install_trans+0xc2>
{
    8000448a:	7139                	addi	sp,sp,-64
    8000448c:	fc06                	sd	ra,56(sp)
    8000448e:	f822                	sd	s0,48(sp)
    80004490:	f426                	sd	s1,40(sp)
    80004492:	f04a                	sd	s2,32(sp)
    80004494:	ec4e                	sd	s3,24(sp)
    80004496:	e852                	sd	s4,16(sp)
    80004498:	e456                	sd	s5,8(sp)
    8000449a:	e05a                	sd	s6,0(sp)
    8000449c:	0080                	addi	s0,sp,64
    8000449e:	8b2a                	mv	s6,a0
    800044a0:	0001da97          	auipc	s5,0x1d
    800044a4:	620a8a93          	addi	s5,s5,1568 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044aa:	0001d997          	auipc	s3,0x1d
    800044ae:	5e698993          	addi	s3,s3,1510 # 80021a90 <log>
    800044b2:	a035                	j	800044de <install_trans+0x60>
      bunpin(dbuf);
    800044b4:	8526                	mv	a0,s1
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	166080e7          	jalr	358(ra) # 8000361c <bunpin>
    brelse(lbuf);
    800044be:	854a                	mv	a0,s2
    800044c0:	fffff097          	auipc	ra,0xfffff
    800044c4:	082080e7          	jalr	130(ra) # 80003542 <brelse>
    brelse(dbuf);
    800044c8:	8526                	mv	a0,s1
    800044ca:	fffff097          	auipc	ra,0xfffff
    800044ce:	078080e7          	jalr	120(ra) # 80003542 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d2:	2a05                	addiw	s4,s4,1
    800044d4:	0a91                	addi	s5,s5,4
    800044d6:	02c9a783          	lw	a5,44(s3)
    800044da:	04fa5963          	bge	s4,a5,8000452c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044de:	0189a583          	lw	a1,24(s3)
    800044e2:	014585bb          	addw	a1,a1,s4
    800044e6:	2585                	addiw	a1,a1,1
    800044e8:	0289a503          	lw	a0,40(s3)
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	f26080e7          	jalr	-218(ra) # 80003412 <bread>
    800044f4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044f6:	000aa583          	lw	a1,0(s5)
    800044fa:	0289a503          	lw	a0,40(s3)
    800044fe:	fffff097          	auipc	ra,0xfffff
    80004502:	f14080e7          	jalr	-236(ra) # 80003412 <bread>
    80004506:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004508:	40000613          	li	a2,1024
    8000450c:	05890593          	addi	a1,s2,88
    80004510:	05850513          	addi	a0,a0,88
    80004514:	ffffd097          	auipc	ra,0xffffd
    80004518:	82c080e7          	jalr	-2004(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000451c:	8526                	mv	a0,s1
    8000451e:	fffff097          	auipc	ra,0xfffff
    80004522:	fe6080e7          	jalr	-26(ra) # 80003504 <bwrite>
    if(recovering == 0)
    80004526:	f80b1ce3          	bnez	s6,800044be <install_trans+0x40>
    8000452a:	b769                	j	800044b4 <install_trans+0x36>
}
    8000452c:	70e2                	ld	ra,56(sp)
    8000452e:	7442                	ld	s0,48(sp)
    80004530:	74a2                	ld	s1,40(sp)
    80004532:	7902                	ld	s2,32(sp)
    80004534:	69e2                	ld	s3,24(sp)
    80004536:	6a42                	ld	s4,16(sp)
    80004538:	6aa2                	ld	s5,8(sp)
    8000453a:	6b02                	ld	s6,0(sp)
    8000453c:	6121                	addi	sp,sp,64
    8000453e:	8082                	ret
    80004540:	8082                	ret

0000000080004542 <initlog>:
{
    80004542:	7179                	addi	sp,sp,-48
    80004544:	f406                	sd	ra,40(sp)
    80004546:	f022                	sd	s0,32(sp)
    80004548:	ec26                	sd	s1,24(sp)
    8000454a:	e84a                	sd	s2,16(sp)
    8000454c:	e44e                	sd	s3,8(sp)
    8000454e:	1800                	addi	s0,sp,48
    80004550:	892a                	mv	s2,a0
    80004552:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004554:	0001d497          	auipc	s1,0x1d
    80004558:	53c48493          	addi	s1,s1,1340 # 80021a90 <log>
    8000455c:	00004597          	auipc	a1,0x4
    80004560:	1ec58593          	addi	a1,a1,492 # 80008748 <syscalls+0x1f0>
    80004564:	8526                	mv	a0,s1
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	5ee080e7          	jalr	1518(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    8000456e:	0149a583          	lw	a1,20(s3)
    80004572:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004574:	0109a783          	lw	a5,16(s3)
    80004578:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000457a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000457e:	854a                	mv	a0,s2
    80004580:	fffff097          	auipc	ra,0xfffff
    80004584:	e92080e7          	jalr	-366(ra) # 80003412 <bread>
  log.lh.n = lh->n;
    80004588:	4d3c                	lw	a5,88(a0)
    8000458a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000458c:	02f05563          	blez	a5,800045b6 <initlog+0x74>
    80004590:	05c50713          	addi	a4,a0,92
    80004594:	0001d697          	auipc	a3,0x1d
    80004598:	52c68693          	addi	a3,a3,1324 # 80021ac0 <log+0x30>
    8000459c:	37fd                	addiw	a5,a5,-1
    8000459e:	1782                	slli	a5,a5,0x20
    800045a0:	9381                	srli	a5,a5,0x20
    800045a2:	078a                	slli	a5,a5,0x2
    800045a4:	06050613          	addi	a2,a0,96
    800045a8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800045aa:	4310                	lw	a2,0(a4)
    800045ac:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800045ae:	0711                	addi	a4,a4,4
    800045b0:	0691                	addi	a3,a3,4
    800045b2:	fef71ce3          	bne	a4,a5,800045aa <initlog+0x68>
  brelse(buf);
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	f8c080e7          	jalr	-116(ra) # 80003542 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045be:	4505                	li	a0,1
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	ebe080e7          	jalr	-322(ra) # 8000447e <install_trans>
  log.lh.n = 0;
    800045c8:	0001d797          	auipc	a5,0x1d
    800045cc:	4e07aa23          	sw	zero,1268(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800045d0:	00000097          	auipc	ra,0x0
    800045d4:	e34080e7          	jalr	-460(ra) # 80004404 <write_head>
}
    800045d8:	70a2                	ld	ra,40(sp)
    800045da:	7402                	ld	s0,32(sp)
    800045dc:	64e2                	ld	s1,24(sp)
    800045de:	6942                	ld	s2,16(sp)
    800045e0:	69a2                	ld	s3,8(sp)
    800045e2:	6145                	addi	sp,sp,48
    800045e4:	8082                	ret

00000000800045e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045e6:	1101                	addi	sp,sp,-32
    800045e8:	ec06                	sd	ra,24(sp)
    800045ea:	e822                	sd	s0,16(sp)
    800045ec:	e426                	sd	s1,8(sp)
    800045ee:	e04a                	sd	s2,0(sp)
    800045f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045f2:	0001d517          	auipc	a0,0x1d
    800045f6:	49e50513          	addi	a0,a0,1182 # 80021a90 <log>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	5ea080e7          	jalr	1514(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004602:	0001d497          	auipc	s1,0x1d
    80004606:	48e48493          	addi	s1,s1,1166 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000460a:	4979                	li	s2,30
    8000460c:	a039                	j	8000461a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000460e:	85a6                	mv	a1,s1
    80004610:	8526                	mv	a0,s1
    80004612:	ffffe097          	auipc	ra,0xffffe
    80004616:	a04080e7          	jalr	-1532(ra) # 80002016 <sleep>
    if(log.committing){
    8000461a:	50dc                	lw	a5,36(s1)
    8000461c:	fbed                	bnez	a5,8000460e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000461e:	509c                	lw	a5,32(s1)
    80004620:	0017871b          	addiw	a4,a5,1
    80004624:	0007069b          	sext.w	a3,a4
    80004628:	0027179b          	slliw	a5,a4,0x2
    8000462c:	9fb9                	addw	a5,a5,a4
    8000462e:	0017979b          	slliw	a5,a5,0x1
    80004632:	54d8                	lw	a4,44(s1)
    80004634:	9fb9                	addw	a5,a5,a4
    80004636:	00f95963          	bge	s2,a5,80004648 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000463a:	85a6                	mv	a1,s1
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffe097          	auipc	ra,0xffffe
    80004642:	9d8080e7          	jalr	-1576(ra) # 80002016 <sleep>
    80004646:	bfd1                	j	8000461a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004648:	0001d517          	auipc	a0,0x1d
    8000464c:	44850513          	addi	a0,a0,1096 # 80021a90 <log>
    80004650:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	646080e7          	jalr	1606(ra) # 80000c98 <release>
      break;
    }
  }
}
    8000465a:	60e2                	ld	ra,24(sp)
    8000465c:	6442                	ld	s0,16(sp)
    8000465e:	64a2                	ld	s1,8(sp)
    80004660:	6902                	ld	s2,0(sp)
    80004662:	6105                	addi	sp,sp,32
    80004664:	8082                	ret

0000000080004666 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004666:	7139                	addi	sp,sp,-64
    80004668:	fc06                	sd	ra,56(sp)
    8000466a:	f822                	sd	s0,48(sp)
    8000466c:	f426                	sd	s1,40(sp)
    8000466e:	f04a                	sd	s2,32(sp)
    80004670:	ec4e                	sd	s3,24(sp)
    80004672:	e852                	sd	s4,16(sp)
    80004674:	e456                	sd	s5,8(sp)
    80004676:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004678:	0001d497          	auipc	s1,0x1d
    8000467c:	41848493          	addi	s1,s1,1048 # 80021a90 <log>
    80004680:	8526                	mv	a0,s1
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	562080e7          	jalr	1378(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000468a:	509c                	lw	a5,32(s1)
    8000468c:	37fd                	addiw	a5,a5,-1
    8000468e:	0007891b          	sext.w	s2,a5
    80004692:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004694:	50dc                	lw	a5,36(s1)
    80004696:	efb9                	bnez	a5,800046f4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004698:	06091663          	bnez	s2,80004704 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000469c:	0001d497          	auipc	s1,0x1d
    800046a0:	3f448493          	addi	s1,s1,1012 # 80021a90 <log>
    800046a4:	4785                	li	a5,1
    800046a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046a8:	8526                	mv	a0,s1
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	5ee080e7          	jalr	1518(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046b2:	54dc                	lw	a5,44(s1)
    800046b4:	06f04763          	bgtz	a5,80004722 <end_op+0xbc>
    acquire(&log.lock);
    800046b8:	0001d497          	auipc	s1,0x1d
    800046bc:	3d848493          	addi	s1,s1,984 # 80021a90 <log>
    800046c0:	8526                	mv	a0,s1
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	522080e7          	jalr	1314(ra) # 80000be4 <acquire>
    log.committing = 0;
    800046ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046ce:	8526                	mv	a0,s1
    800046d0:	ffffe097          	auipc	ra,0xffffe
    800046d4:	ad2080e7          	jalr	-1326(ra) # 800021a2 <wakeup>
    release(&log.lock);
    800046d8:	8526                	mv	a0,s1
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	5be080e7          	jalr	1470(ra) # 80000c98 <release>
}
    800046e2:	70e2                	ld	ra,56(sp)
    800046e4:	7442                	ld	s0,48(sp)
    800046e6:	74a2                	ld	s1,40(sp)
    800046e8:	7902                	ld	s2,32(sp)
    800046ea:	69e2                	ld	s3,24(sp)
    800046ec:	6a42                	ld	s4,16(sp)
    800046ee:	6aa2                	ld	s5,8(sp)
    800046f0:	6121                	addi	sp,sp,64
    800046f2:	8082                	ret
    panic("log.committing");
    800046f4:	00004517          	auipc	a0,0x4
    800046f8:	05c50513          	addi	a0,a0,92 # 80008750 <syscalls+0x1f8>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	e42080e7          	jalr	-446(ra) # 8000053e <panic>
    wakeup(&log);
    80004704:	0001d497          	auipc	s1,0x1d
    80004708:	38c48493          	addi	s1,s1,908 # 80021a90 <log>
    8000470c:	8526                	mv	a0,s1
    8000470e:	ffffe097          	auipc	ra,0xffffe
    80004712:	a94080e7          	jalr	-1388(ra) # 800021a2 <wakeup>
  release(&log.lock);
    80004716:	8526                	mv	a0,s1
    80004718:	ffffc097          	auipc	ra,0xffffc
    8000471c:	580080e7          	jalr	1408(ra) # 80000c98 <release>
  if(do_commit){
    80004720:	b7c9                	j	800046e2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004722:	0001da97          	auipc	s5,0x1d
    80004726:	39ea8a93          	addi	s5,s5,926 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000472a:	0001da17          	auipc	s4,0x1d
    8000472e:	366a0a13          	addi	s4,s4,870 # 80021a90 <log>
    80004732:	018a2583          	lw	a1,24(s4)
    80004736:	012585bb          	addw	a1,a1,s2
    8000473a:	2585                	addiw	a1,a1,1
    8000473c:	028a2503          	lw	a0,40(s4)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	cd2080e7          	jalr	-814(ra) # 80003412 <bread>
    80004748:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000474a:	000aa583          	lw	a1,0(s5)
    8000474e:	028a2503          	lw	a0,40(s4)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	cc0080e7          	jalr	-832(ra) # 80003412 <bread>
    8000475a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000475c:	40000613          	li	a2,1024
    80004760:	05850593          	addi	a1,a0,88
    80004764:	05848513          	addi	a0,s1,88
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	5d8080e7          	jalr	1496(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    80004770:	8526                	mv	a0,s1
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	d92080e7          	jalr	-622(ra) # 80003504 <bwrite>
    brelse(from);
    8000477a:	854e                	mv	a0,s3
    8000477c:	fffff097          	auipc	ra,0xfffff
    80004780:	dc6080e7          	jalr	-570(ra) # 80003542 <brelse>
    brelse(to);
    80004784:	8526                	mv	a0,s1
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	dbc080e7          	jalr	-580(ra) # 80003542 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000478e:	2905                	addiw	s2,s2,1
    80004790:	0a91                	addi	s5,s5,4
    80004792:	02ca2783          	lw	a5,44(s4)
    80004796:	f8f94ee3          	blt	s2,a5,80004732 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	c6a080e7          	jalr	-918(ra) # 80004404 <write_head>
    install_trans(0); // Now install writes to home locations
    800047a2:	4501                	li	a0,0
    800047a4:	00000097          	auipc	ra,0x0
    800047a8:	cda080e7          	jalr	-806(ra) # 8000447e <install_trans>
    log.lh.n = 0;
    800047ac:	0001d797          	auipc	a5,0x1d
    800047b0:	3007a823          	sw	zero,784(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	c50080e7          	jalr	-944(ra) # 80004404 <write_head>
    800047bc:	bdf5                	j	800046b8 <end_op+0x52>

00000000800047be <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047be:	1101                	addi	sp,sp,-32
    800047c0:	ec06                	sd	ra,24(sp)
    800047c2:	e822                	sd	s0,16(sp)
    800047c4:	e426                	sd	s1,8(sp)
    800047c6:	e04a                	sd	s2,0(sp)
    800047c8:	1000                	addi	s0,sp,32
    800047ca:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047cc:	0001d917          	auipc	s2,0x1d
    800047d0:	2c490913          	addi	s2,s2,708 # 80021a90 <log>
    800047d4:	854a                	mv	a0,s2
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	40e080e7          	jalr	1038(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047de:	02c92603          	lw	a2,44(s2)
    800047e2:	47f5                	li	a5,29
    800047e4:	06c7c563          	blt	a5,a2,8000484e <log_write+0x90>
    800047e8:	0001d797          	auipc	a5,0x1d
    800047ec:	2c47a783          	lw	a5,708(a5) # 80021aac <log+0x1c>
    800047f0:	37fd                	addiw	a5,a5,-1
    800047f2:	04f65e63          	bge	a2,a5,8000484e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047f6:	0001d797          	auipc	a5,0x1d
    800047fa:	2ba7a783          	lw	a5,698(a5) # 80021ab0 <log+0x20>
    800047fe:	06f05063          	blez	a5,8000485e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004802:	4781                	li	a5,0
    80004804:	06c05563          	blez	a2,8000486e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004808:	44cc                	lw	a1,12(s1)
    8000480a:	0001d717          	auipc	a4,0x1d
    8000480e:	2b670713          	addi	a4,a4,694 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004812:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004814:	4314                	lw	a3,0(a4)
    80004816:	04b68c63          	beq	a3,a1,8000486e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000481a:	2785                	addiw	a5,a5,1
    8000481c:	0711                	addi	a4,a4,4
    8000481e:	fef61be3          	bne	a2,a5,80004814 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004822:	0621                	addi	a2,a2,8
    80004824:	060a                	slli	a2,a2,0x2
    80004826:	0001d797          	auipc	a5,0x1d
    8000482a:	26a78793          	addi	a5,a5,618 # 80021a90 <log>
    8000482e:	963e                	add	a2,a2,a5
    80004830:	44dc                	lw	a5,12(s1)
    80004832:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004834:	8526                	mv	a0,s1
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	daa080e7          	jalr	-598(ra) # 800035e0 <bpin>
    log.lh.n++;
    8000483e:	0001d717          	auipc	a4,0x1d
    80004842:	25270713          	addi	a4,a4,594 # 80021a90 <log>
    80004846:	575c                	lw	a5,44(a4)
    80004848:	2785                	addiw	a5,a5,1
    8000484a:	d75c                	sw	a5,44(a4)
    8000484c:	a835                	j	80004888 <log_write+0xca>
    panic("too big a transaction");
    8000484e:	00004517          	auipc	a0,0x4
    80004852:	f1250513          	addi	a0,a0,-238 # 80008760 <syscalls+0x208>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    8000485e:	00004517          	auipc	a0,0x4
    80004862:	f1a50513          	addi	a0,a0,-230 # 80008778 <syscalls+0x220>
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	cd8080e7          	jalr	-808(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    8000486e:	00878713          	addi	a4,a5,8
    80004872:	00271693          	slli	a3,a4,0x2
    80004876:	0001d717          	auipc	a4,0x1d
    8000487a:	21a70713          	addi	a4,a4,538 # 80021a90 <log>
    8000487e:	9736                	add	a4,a4,a3
    80004880:	44d4                	lw	a3,12(s1)
    80004882:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004884:	faf608e3          	beq	a2,a5,80004834 <log_write+0x76>
  }
  release(&log.lock);
    80004888:	0001d517          	auipc	a0,0x1d
    8000488c:	20850513          	addi	a0,a0,520 # 80021a90 <log>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	408080e7          	jalr	1032(ra) # 80000c98 <release>
}
    80004898:	60e2                	ld	ra,24(sp)
    8000489a:	6442                	ld	s0,16(sp)
    8000489c:	64a2                	ld	s1,8(sp)
    8000489e:	6902                	ld	s2,0(sp)
    800048a0:	6105                	addi	sp,sp,32
    800048a2:	8082                	ret

00000000800048a4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048a4:	1101                	addi	sp,sp,-32
    800048a6:	ec06                	sd	ra,24(sp)
    800048a8:	e822                	sd	s0,16(sp)
    800048aa:	e426                	sd	s1,8(sp)
    800048ac:	e04a                	sd	s2,0(sp)
    800048ae:	1000                	addi	s0,sp,32
    800048b0:	84aa                	mv	s1,a0
    800048b2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048b4:	00004597          	auipc	a1,0x4
    800048b8:	ee458593          	addi	a1,a1,-284 # 80008798 <syscalls+0x240>
    800048bc:	0521                	addi	a0,a0,8
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	296080e7          	jalr	662(ra) # 80000b54 <initlock>
  lk->name = name;
    800048c6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ce:	0204a423          	sw	zero,40(s1)
}
    800048d2:	60e2                	ld	ra,24(sp)
    800048d4:	6442                	ld	s0,16(sp)
    800048d6:	64a2                	ld	s1,8(sp)
    800048d8:	6902                	ld	s2,0(sp)
    800048da:	6105                	addi	sp,sp,32
    800048dc:	8082                	ret

00000000800048de <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048de:	1101                	addi	sp,sp,-32
    800048e0:	ec06                	sd	ra,24(sp)
    800048e2:	e822                	sd	s0,16(sp)
    800048e4:	e426                	sd	s1,8(sp)
    800048e6:	e04a                	sd	s2,0(sp)
    800048e8:	1000                	addi	s0,sp,32
    800048ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048ec:	00850913          	addi	s2,a0,8
    800048f0:	854a                	mv	a0,s2
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	2f2080e7          	jalr	754(ra) # 80000be4 <acquire>
  while (lk->locked) {
    800048fa:	409c                	lw	a5,0(s1)
    800048fc:	cb89                	beqz	a5,8000490e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048fe:	85ca                	mv	a1,s2
    80004900:	8526                	mv	a0,s1
    80004902:	ffffd097          	auipc	ra,0xffffd
    80004906:	714080e7          	jalr	1812(ra) # 80002016 <sleep>
  while (lk->locked) {
    8000490a:	409c                	lw	a5,0(s1)
    8000490c:	fbed                	bnez	a5,800048fe <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000490e:	4785                	li	a5,1
    80004910:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004912:	ffffd097          	auipc	ra,0xffffd
    80004916:	09e080e7          	jalr	158(ra) # 800019b0 <myproc>
    8000491a:	591c                	lw	a5,48(a0)
    8000491c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000491e:	854a                	mv	a0,s2
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	378080e7          	jalr	888(ra) # 80000c98 <release>
}
    80004928:	60e2                	ld	ra,24(sp)
    8000492a:	6442                	ld	s0,16(sp)
    8000492c:	64a2                	ld	s1,8(sp)
    8000492e:	6902                	ld	s2,0(sp)
    80004930:	6105                	addi	sp,sp,32
    80004932:	8082                	ret

0000000080004934 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004934:	1101                	addi	sp,sp,-32
    80004936:	ec06                	sd	ra,24(sp)
    80004938:	e822                	sd	s0,16(sp)
    8000493a:	e426                	sd	s1,8(sp)
    8000493c:	e04a                	sd	s2,0(sp)
    8000493e:	1000                	addi	s0,sp,32
    80004940:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004942:	00850913          	addi	s2,a0,8
    80004946:	854a                	mv	a0,s2
    80004948:	ffffc097          	auipc	ra,0xffffc
    8000494c:	29c080e7          	jalr	668(ra) # 80000be4 <acquire>
  lk->locked = 0;
    80004950:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004954:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004958:	8526                	mv	a0,s1
    8000495a:	ffffe097          	auipc	ra,0xffffe
    8000495e:	848080e7          	jalr	-1976(ra) # 800021a2 <wakeup>
  release(&lk->lk);
    80004962:	854a                	mv	a0,s2
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	334080e7          	jalr	820(ra) # 80000c98 <release>
}
    8000496c:	60e2                	ld	ra,24(sp)
    8000496e:	6442                	ld	s0,16(sp)
    80004970:	64a2                	ld	s1,8(sp)
    80004972:	6902                	ld	s2,0(sp)
    80004974:	6105                	addi	sp,sp,32
    80004976:	8082                	ret

0000000080004978 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004978:	7179                	addi	sp,sp,-48
    8000497a:	f406                	sd	ra,40(sp)
    8000497c:	f022                	sd	s0,32(sp)
    8000497e:	ec26                	sd	s1,24(sp)
    80004980:	e84a                	sd	s2,16(sp)
    80004982:	e44e                	sd	s3,8(sp)
    80004984:	1800                	addi	s0,sp,48
    80004986:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004988:	00850913          	addi	s2,a0,8
    8000498c:	854a                	mv	a0,s2
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	256080e7          	jalr	598(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004996:	409c                	lw	a5,0(s1)
    80004998:	ef99                	bnez	a5,800049b6 <holdingsleep+0x3e>
    8000499a:	4481                	li	s1,0
  release(&lk->lk);
    8000499c:	854a                	mv	a0,s2
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	2fa080e7          	jalr	762(ra) # 80000c98 <release>
  return r;
}
    800049a6:	8526                	mv	a0,s1
    800049a8:	70a2                	ld	ra,40(sp)
    800049aa:	7402                	ld	s0,32(sp)
    800049ac:	64e2                	ld	s1,24(sp)
    800049ae:	6942                	ld	s2,16(sp)
    800049b0:	69a2                	ld	s3,8(sp)
    800049b2:	6145                	addi	sp,sp,48
    800049b4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049b6:	0284a983          	lw	s3,40(s1)
    800049ba:	ffffd097          	auipc	ra,0xffffd
    800049be:	ff6080e7          	jalr	-10(ra) # 800019b0 <myproc>
    800049c2:	5904                	lw	s1,48(a0)
    800049c4:	413484b3          	sub	s1,s1,s3
    800049c8:	0014b493          	seqz	s1,s1
    800049cc:	bfc1                	j	8000499c <holdingsleep+0x24>

00000000800049ce <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049ce:	1141                	addi	sp,sp,-16
    800049d0:	e406                	sd	ra,8(sp)
    800049d2:	e022                	sd	s0,0(sp)
    800049d4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049d6:	00004597          	auipc	a1,0x4
    800049da:	dd258593          	addi	a1,a1,-558 # 800087a8 <syscalls+0x250>
    800049de:	0001d517          	auipc	a0,0x1d
    800049e2:	1fa50513          	addi	a0,a0,506 # 80021bd8 <ftable>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	16e080e7          	jalr	366(ra) # 80000b54 <initlock>
}
    800049ee:	60a2                	ld	ra,8(sp)
    800049f0:	6402                	ld	s0,0(sp)
    800049f2:	0141                	addi	sp,sp,16
    800049f4:	8082                	ret

00000000800049f6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049f6:	1101                	addi	sp,sp,-32
    800049f8:	ec06                	sd	ra,24(sp)
    800049fa:	e822                	sd	s0,16(sp)
    800049fc:	e426                	sd	s1,8(sp)
    800049fe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a00:	0001d517          	auipc	a0,0x1d
    80004a04:	1d850513          	addi	a0,a0,472 # 80021bd8 <ftable>
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	1dc080e7          	jalr	476(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a10:	0001d497          	auipc	s1,0x1d
    80004a14:	1e048493          	addi	s1,s1,480 # 80021bf0 <ftable+0x18>
    80004a18:	0001e717          	auipc	a4,0x1e
    80004a1c:	17870713          	addi	a4,a4,376 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004a20:	40dc                	lw	a5,4(s1)
    80004a22:	cf99                	beqz	a5,80004a40 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a24:	02848493          	addi	s1,s1,40
    80004a28:	fee49ce3          	bne	s1,a4,80004a20 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a2c:	0001d517          	auipc	a0,0x1d
    80004a30:	1ac50513          	addi	a0,a0,428 # 80021bd8 <ftable>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	264080e7          	jalr	612(ra) # 80000c98 <release>
  return 0;
    80004a3c:	4481                	li	s1,0
    80004a3e:	a819                	j	80004a54 <filealloc+0x5e>
      f->ref = 1;
    80004a40:	4785                	li	a5,1
    80004a42:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a44:	0001d517          	auipc	a0,0x1d
    80004a48:	19450513          	addi	a0,a0,404 # 80021bd8 <ftable>
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	24c080e7          	jalr	588(ra) # 80000c98 <release>
}
    80004a54:	8526                	mv	a0,s1
    80004a56:	60e2                	ld	ra,24(sp)
    80004a58:	6442                	ld	s0,16(sp)
    80004a5a:	64a2                	ld	s1,8(sp)
    80004a5c:	6105                	addi	sp,sp,32
    80004a5e:	8082                	ret

0000000080004a60 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a60:	1101                	addi	sp,sp,-32
    80004a62:	ec06                	sd	ra,24(sp)
    80004a64:	e822                	sd	s0,16(sp)
    80004a66:	e426                	sd	s1,8(sp)
    80004a68:	1000                	addi	s0,sp,32
    80004a6a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a6c:	0001d517          	auipc	a0,0x1d
    80004a70:	16c50513          	addi	a0,a0,364 # 80021bd8 <ftable>
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	170080e7          	jalr	368(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004a7c:	40dc                	lw	a5,4(s1)
    80004a7e:	02f05263          	blez	a5,80004aa2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a82:	2785                	addiw	a5,a5,1
    80004a84:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a86:	0001d517          	auipc	a0,0x1d
    80004a8a:	15250513          	addi	a0,a0,338 # 80021bd8 <ftable>
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	20a080e7          	jalr	522(ra) # 80000c98 <release>
  return f;
}
    80004a96:	8526                	mv	a0,s1
    80004a98:	60e2                	ld	ra,24(sp)
    80004a9a:	6442                	ld	s0,16(sp)
    80004a9c:	64a2                	ld	s1,8(sp)
    80004a9e:	6105                	addi	sp,sp,32
    80004aa0:	8082                	ret
    panic("filedup");
    80004aa2:	00004517          	auipc	a0,0x4
    80004aa6:	d0e50513          	addi	a0,a0,-754 # 800087b0 <syscalls+0x258>
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	a94080e7          	jalr	-1388(ra) # 8000053e <panic>

0000000080004ab2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ab2:	7139                	addi	sp,sp,-64
    80004ab4:	fc06                	sd	ra,56(sp)
    80004ab6:	f822                	sd	s0,48(sp)
    80004ab8:	f426                	sd	s1,40(sp)
    80004aba:	f04a                	sd	s2,32(sp)
    80004abc:	ec4e                	sd	s3,24(sp)
    80004abe:	e852                	sd	s4,16(sp)
    80004ac0:	e456                	sd	s5,8(sp)
    80004ac2:	0080                	addi	s0,sp,64
    80004ac4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ac6:	0001d517          	auipc	a0,0x1d
    80004aca:	11250513          	addi	a0,a0,274 # 80021bd8 <ftable>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	116080e7          	jalr	278(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004ad6:	40dc                	lw	a5,4(s1)
    80004ad8:	06f05163          	blez	a5,80004b3a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004adc:	37fd                	addiw	a5,a5,-1
    80004ade:	0007871b          	sext.w	a4,a5
    80004ae2:	c0dc                	sw	a5,4(s1)
    80004ae4:	06e04363          	bgtz	a4,80004b4a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ae8:	0004a903          	lw	s2,0(s1)
    80004aec:	0094ca83          	lbu	s5,9(s1)
    80004af0:	0104ba03          	ld	s4,16(s1)
    80004af4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004af8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004afc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b00:	0001d517          	auipc	a0,0x1d
    80004b04:	0d850513          	addi	a0,a0,216 # 80021bd8 <ftable>
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	190080e7          	jalr	400(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004b10:	4785                	li	a5,1
    80004b12:	04f90d63          	beq	s2,a5,80004b6c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b16:	3979                	addiw	s2,s2,-2
    80004b18:	4785                	li	a5,1
    80004b1a:	0527e063          	bltu	a5,s2,80004b5a <fileclose+0xa8>
    begin_op();
    80004b1e:	00000097          	auipc	ra,0x0
    80004b22:	ac8080e7          	jalr	-1336(ra) # 800045e6 <begin_op>
    iput(ff.ip);
    80004b26:	854e                	mv	a0,s3
    80004b28:	fffff097          	auipc	ra,0xfffff
    80004b2c:	2a6080e7          	jalr	678(ra) # 80003dce <iput>
    end_op();
    80004b30:	00000097          	auipc	ra,0x0
    80004b34:	b36080e7          	jalr	-1226(ra) # 80004666 <end_op>
    80004b38:	a00d                	j	80004b5a <fileclose+0xa8>
    panic("fileclose");
    80004b3a:	00004517          	auipc	a0,0x4
    80004b3e:	c7e50513          	addi	a0,a0,-898 # 800087b8 <syscalls+0x260>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	9fc080e7          	jalr	-1540(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004b4a:	0001d517          	auipc	a0,0x1d
    80004b4e:	08e50513          	addi	a0,a0,142 # 80021bd8 <ftable>
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	146080e7          	jalr	326(ra) # 80000c98 <release>
  }
}
    80004b5a:	70e2                	ld	ra,56(sp)
    80004b5c:	7442                	ld	s0,48(sp)
    80004b5e:	74a2                	ld	s1,40(sp)
    80004b60:	7902                	ld	s2,32(sp)
    80004b62:	69e2                	ld	s3,24(sp)
    80004b64:	6a42                	ld	s4,16(sp)
    80004b66:	6aa2                	ld	s5,8(sp)
    80004b68:	6121                	addi	sp,sp,64
    80004b6a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b6c:	85d6                	mv	a1,s5
    80004b6e:	8552                	mv	a0,s4
    80004b70:	00000097          	auipc	ra,0x0
    80004b74:	34c080e7          	jalr	844(ra) # 80004ebc <pipeclose>
    80004b78:	b7cd                	j	80004b5a <fileclose+0xa8>

0000000080004b7a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b7a:	715d                	addi	sp,sp,-80
    80004b7c:	e486                	sd	ra,72(sp)
    80004b7e:	e0a2                	sd	s0,64(sp)
    80004b80:	fc26                	sd	s1,56(sp)
    80004b82:	f84a                	sd	s2,48(sp)
    80004b84:	f44e                	sd	s3,40(sp)
    80004b86:	0880                	addi	s0,sp,80
    80004b88:	84aa                	mv	s1,a0
    80004b8a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b8c:	ffffd097          	auipc	ra,0xffffd
    80004b90:	e24080e7          	jalr	-476(ra) # 800019b0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b94:	409c                	lw	a5,0(s1)
    80004b96:	37f9                	addiw	a5,a5,-2
    80004b98:	4705                	li	a4,1
    80004b9a:	04f76763          	bltu	a4,a5,80004be8 <filestat+0x6e>
    80004b9e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004ba0:	6c88                	ld	a0,24(s1)
    80004ba2:	fffff097          	auipc	ra,0xfffff
    80004ba6:	072080e7          	jalr	114(ra) # 80003c14 <ilock>
    stati(f->ip, &st);
    80004baa:	fb840593          	addi	a1,s0,-72
    80004bae:	6c88                	ld	a0,24(s1)
    80004bb0:	fffff097          	auipc	ra,0xfffff
    80004bb4:	2ee080e7          	jalr	750(ra) # 80003e9e <stati>
    iunlock(f->ip);
    80004bb8:	6c88                	ld	a0,24(s1)
    80004bba:	fffff097          	auipc	ra,0xfffff
    80004bbe:	11c080e7          	jalr	284(ra) # 80003cd6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bc2:	46e1                	li	a3,24
    80004bc4:	fb840613          	addi	a2,s0,-72
    80004bc8:	85ce                	mv	a1,s3
    80004bca:	07093503          	ld	a0,112(s2)
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	aa4080e7          	jalr	-1372(ra) # 80001672 <copyout>
    80004bd6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bda:	60a6                	ld	ra,72(sp)
    80004bdc:	6406                	ld	s0,64(sp)
    80004bde:	74e2                	ld	s1,56(sp)
    80004be0:	7942                	ld	s2,48(sp)
    80004be2:	79a2                	ld	s3,40(sp)
    80004be4:	6161                	addi	sp,sp,80
    80004be6:	8082                	ret
  return -1;
    80004be8:	557d                	li	a0,-1
    80004bea:	bfc5                	j	80004bda <filestat+0x60>

0000000080004bec <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004bec:	7179                	addi	sp,sp,-48
    80004bee:	f406                	sd	ra,40(sp)
    80004bf0:	f022                	sd	s0,32(sp)
    80004bf2:	ec26                	sd	s1,24(sp)
    80004bf4:	e84a                	sd	s2,16(sp)
    80004bf6:	e44e                	sd	s3,8(sp)
    80004bf8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bfa:	00854783          	lbu	a5,8(a0)
    80004bfe:	c3d5                	beqz	a5,80004ca2 <fileread+0xb6>
    80004c00:	84aa                	mv	s1,a0
    80004c02:	89ae                	mv	s3,a1
    80004c04:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c06:	411c                	lw	a5,0(a0)
    80004c08:	4705                	li	a4,1
    80004c0a:	04e78963          	beq	a5,a4,80004c5c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c0e:	470d                	li	a4,3
    80004c10:	04e78d63          	beq	a5,a4,80004c6a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c14:	4709                	li	a4,2
    80004c16:	06e79e63          	bne	a5,a4,80004c92 <fileread+0xa6>
    ilock(f->ip);
    80004c1a:	6d08                	ld	a0,24(a0)
    80004c1c:	fffff097          	auipc	ra,0xfffff
    80004c20:	ff8080e7          	jalr	-8(ra) # 80003c14 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c24:	874a                	mv	a4,s2
    80004c26:	5094                	lw	a3,32(s1)
    80004c28:	864e                	mv	a2,s3
    80004c2a:	4585                	li	a1,1
    80004c2c:	6c88                	ld	a0,24(s1)
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	29a080e7          	jalr	666(ra) # 80003ec8 <readi>
    80004c36:	892a                	mv	s2,a0
    80004c38:	00a05563          	blez	a0,80004c42 <fileread+0x56>
      f->off += r;
    80004c3c:	509c                	lw	a5,32(s1)
    80004c3e:	9fa9                	addw	a5,a5,a0
    80004c40:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c42:	6c88                	ld	a0,24(s1)
    80004c44:	fffff097          	auipc	ra,0xfffff
    80004c48:	092080e7          	jalr	146(ra) # 80003cd6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c4c:	854a                	mv	a0,s2
    80004c4e:	70a2                	ld	ra,40(sp)
    80004c50:	7402                	ld	s0,32(sp)
    80004c52:	64e2                	ld	s1,24(sp)
    80004c54:	6942                	ld	s2,16(sp)
    80004c56:	69a2                	ld	s3,8(sp)
    80004c58:	6145                	addi	sp,sp,48
    80004c5a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c5c:	6908                	ld	a0,16(a0)
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	3c8080e7          	jalr	968(ra) # 80005026 <piperead>
    80004c66:	892a                	mv	s2,a0
    80004c68:	b7d5                	j	80004c4c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c6a:	02451783          	lh	a5,36(a0)
    80004c6e:	03079693          	slli	a3,a5,0x30
    80004c72:	92c1                	srli	a3,a3,0x30
    80004c74:	4725                	li	a4,9
    80004c76:	02d76863          	bltu	a4,a3,80004ca6 <fileread+0xba>
    80004c7a:	0792                	slli	a5,a5,0x4
    80004c7c:	0001d717          	auipc	a4,0x1d
    80004c80:	ebc70713          	addi	a4,a4,-324 # 80021b38 <devsw>
    80004c84:	97ba                	add	a5,a5,a4
    80004c86:	639c                	ld	a5,0(a5)
    80004c88:	c38d                	beqz	a5,80004caa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c8a:	4505                	li	a0,1
    80004c8c:	9782                	jalr	a5
    80004c8e:	892a                	mv	s2,a0
    80004c90:	bf75                	j	80004c4c <fileread+0x60>
    panic("fileread");
    80004c92:	00004517          	auipc	a0,0x4
    80004c96:	b3650513          	addi	a0,a0,-1226 # 800087c8 <syscalls+0x270>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	8a4080e7          	jalr	-1884(ra) # 8000053e <panic>
    return -1;
    80004ca2:	597d                	li	s2,-1
    80004ca4:	b765                	j	80004c4c <fileread+0x60>
      return -1;
    80004ca6:	597d                	li	s2,-1
    80004ca8:	b755                	j	80004c4c <fileread+0x60>
    80004caa:	597d                	li	s2,-1
    80004cac:	b745                	j	80004c4c <fileread+0x60>

0000000080004cae <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004cae:	715d                	addi	sp,sp,-80
    80004cb0:	e486                	sd	ra,72(sp)
    80004cb2:	e0a2                	sd	s0,64(sp)
    80004cb4:	fc26                	sd	s1,56(sp)
    80004cb6:	f84a                	sd	s2,48(sp)
    80004cb8:	f44e                	sd	s3,40(sp)
    80004cba:	f052                	sd	s4,32(sp)
    80004cbc:	ec56                	sd	s5,24(sp)
    80004cbe:	e85a                	sd	s6,16(sp)
    80004cc0:	e45e                	sd	s7,8(sp)
    80004cc2:	e062                	sd	s8,0(sp)
    80004cc4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cc6:	00954783          	lbu	a5,9(a0)
    80004cca:	10078663          	beqz	a5,80004dd6 <filewrite+0x128>
    80004cce:	892a                	mv	s2,a0
    80004cd0:	8aae                	mv	s5,a1
    80004cd2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cd4:	411c                	lw	a5,0(a0)
    80004cd6:	4705                	li	a4,1
    80004cd8:	02e78263          	beq	a5,a4,80004cfc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cdc:	470d                	li	a4,3
    80004cde:	02e78663          	beq	a5,a4,80004d0a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ce2:	4709                	li	a4,2
    80004ce4:	0ee79163          	bne	a5,a4,80004dc6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ce8:	0ac05d63          	blez	a2,80004da2 <filewrite+0xf4>
    int i = 0;
    80004cec:	4981                	li	s3,0
    80004cee:	6b05                	lui	s6,0x1
    80004cf0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004cf4:	6b85                	lui	s7,0x1
    80004cf6:	c00b8b9b          	addiw	s7,s7,-1024
    80004cfa:	a861                	j	80004d92 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cfc:	6908                	ld	a0,16(a0)
    80004cfe:	00000097          	auipc	ra,0x0
    80004d02:	22e080e7          	jalr	558(ra) # 80004f2c <pipewrite>
    80004d06:	8a2a                	mv	s4,a0
    80004d08:	a045                	j	80004da8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d0a:	02451783          	lh	a5,36(a0)
    80004d0e:	03079693          	slli	a3,a5,0x30
    80004d12:	92c1                	srli	a3,a3,0x30
    80004d14:	4725                	li	a4,9
    80004d16:	0cd76263          	bltu	a4,a3,80004dda <filewrite+0x12c>
    80004d1a:	0792                	slli	a5,a5,0x4
    80004d1c:	0001d717          	auipc	a4,0x1d
    80004d20:	e1c70713          	addi	a4,a4,-484 # 80021b38 <devsw>
    80004d24:	97ba                	add	a5,a5,a4
    80004d26:	679c                	ld	a5,8(a5)
    80004d28:	cbdd                	beqz	a5,80004dde <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d2a:	4505                	li	a0,1
    80004d2c:	9782                	jalr	a5
    80004d2e:	8a2a                	mv	s4,a0
    80004d30:	a8a5                	j	80004da8 <filewrite+0xfa>
    80004d32:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d36:	00000097          	auipc	ra,0x0
    80004d3a:	8b0080e7          	jalr	-1872(ra) # 800045e6 <begin_op>
      ilock(f->ip);
    80004d3e:	01893503          	ld	a0,24(s2)
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	ed2080e7          	jalr	-302(ra) # 80003c14 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d4a:	8762                	mv	a4,s8
    80004d4c:	02092683          	lw	a3,32(s2)
    80004d50:	01598633          	add	a2,s3,s5
    80004d54:	4585                	li	a1,1
    80004d56:	01893503          	ld	a0,24(s2)
    80004d5a:	fffff097          	auipc	ra,0xfffff
    80004d5e:	266080e7          	jalr	614(ra) # 80003fc0 <writei>
    80004d62:	84aa                	mv	s1,a0
    80004d64:	00a05763          	blez	a0,80004d72 <filewrite+0xc4>
        f->off += r;
    80004d68:	02092783          	lw	a5,32(s2)
    80004d6c:	9fa9                	addw	a5,a5,a0
    80004d6e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d72:	01893503          	ld	a0,24(s2)
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	f60080e7          	jalr	-160(ra) # 80003cd6 <iunlock>
      end_op();
    80004d7e:	00000097          	auipc	ra,0x0
    80004d82:	8e8080e7          	jalr	-1816(ra) # 80004666 <end_op>

      if(r != n1){
    80004d86:	009c1f63          	bne	s8,s1,80004da4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d8a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d8e:	0149db63          	bge	s3,s4,80004da4 <filewrite+0xf6>
      int n1 = n - i;
    80004d92:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d96:	84be                	mv	s1,a5
    80004d98:	2781                	sext.w	a5,a5
    80004d9a:	f8fb5ce3          	bge	s6,a5,80004d32 <filewrite+0x84>
    80004d9e:	84de                	mv	s1,s7
    80004da0:	bf49                	j	80004d32 <filewrite+0x84>
    int i = 0;
    80004da2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004da4:	013a1f63          	bne	s4,s3,80004dc2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004da8:	8552                	mv	a0,s4
    80004daa:	60a6                	ld	ra,72(sp)
    80004dac:	6406                	ld	s0,64(sp)
    80004dae:	74e2                	ld	s1,56(sp)
    80004db0:	7942                	ld	s2,48(sp)
    80004db2:	79a2                	ld	s3,40(sp)
    80004db4:	7a02                	ld	s4,32(sp)
    80004db6:	6ae2                	ld	s5,24(sp)
    80004db8:	6b42                	ld	s6,16(sp)
    80004dba:	6ba2                	ld	s7,8(sp)
    80004dbc:	6c02                	ld	s8,0(sp)
    80004dbe:	6161                	addi	sp,sp,80
    80004dc0:	8082                	ret
    ret = (i == n ? n : -1);
    80004dc2:	5a7d                	li	s4,-1
    80004dc4:	b7d5                	j	80004da8 <filewrite+0xfa>
    panic("filewrite");
    80004dc6:	00004517          	auipc	a0,0x4
    80004dca:	a1250513          	addi	a0,a0,-1518 # 800087d8 <syscalls+0x280>
    80004dce:	ffffb097          	auipc	ra,0xffffb
    80004dd2:	770080e7          	jalr	1904(ra) # 8000053e <panic>
    return -1;
    80004dd6:	5a7d                	li	s4,-1
    80004dd8:	bfc1                	j	80004da8 <filewrite+0xfa>
      return -1;
    80004dda:	5a7d                	li	s4,-1
    80004ddc:	b7f1                	j	80004da8 <filewrite+0xfa>
    80004dde:	5a7d                	li	s4,-1
    80004de0:	b7e1                	j	80004da8 <filewrite+0xfa>

0000000080004de2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004de2:	7179                	addi	sp,sp,-48
    80004de4:	f406                	sd	ra,40(sp)
    80004de6:	f022                	sd	s0,32(sp)
    80004de8:	ec26                	sd	s1,24(sp)
    80004dea:	e84a                	sd	s2,16(sp)
    80004dec:	e44e                	sd	s3,8(sp)
    80004dee:	e052                	sd	s4,0(sp)
    80004df0:	1800                	addi	s0,sp,48
    80004df2:	84aa                	mv	s1,a0
    80004df4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004df6:	0005b023          	sd	zero,0(a1)
    80004dfa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dfe:	00000097          	auipc	ra,0x0
    80004e02:	bf8080e7          	jalr	-1032(ra) # 800049f6 <filealloc>
    80004e06:	e088                	sd	a0,0(s1)
    80004e08:	c551                	beqz	a0,80004e94 <pipealloc+0xb2>
    80004e0a:	00000097          	auipc	ra,0x0
    80004e0e:	bec080e7          	jalr	-1044(ra) # 800049f6 <filealloc>
    80004e12:	00aa3023          	sd	a0,0(s4)
    80004e16:	c92d                	beqz	a0,80004e88 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e18:	ffffc097          	auipc	ra,0xffffc
    80004e1c:	cdc080e7          	jalr	-804(ra) # 80000af4 <kalloc>
    80004e20:	892a                	mv	s2,a0
    80004e22:	c125                	beqz	a0,80004e82 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e24:	4985                	li	s3,1
    80004e26:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e2a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e2e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e32:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e36:	00004597          	auipc	a1,0x4
    80004e3a:	9b258593          	addi	a1,a1,-1614 # 800087e8 <syscalls+0x290>
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	d16080e7          	jalr	-746(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    80004e46:	609c                	ld	a5,0(s1)
    80004e48:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e4c:	609c                	ld	a5,0(s1)
    80004e4e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e52:	609c                	ld	a5,0(s1)
    80004e54:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e58:	609c                	ld	a5,0(s1)
    80004e5a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e5e:	000a3783          	ld	a5,0(s4)
    80004e62:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e66:	000a3783          	ld	a5,0(s4)
    80004e6a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e6e:	000a3783          	ld	a5,0(s4)
    80004e72:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e76:	000a3783          	ld	a5,0(s4)
    80004e7a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e7e:	4501                	li	a0,0
    80004e80:	a025                	j	80004ea8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e82:	6088                	ld	a0,0(s1)
    80004e84:	e501                	bnez	a0,80004e8c <pipealloc+0xaa>
    80004e86:	a039                	j	80004e94 <pipealloc+0xb2>
    80004e88:	6088                	ld	a0,0(s1)
    80004e8a:	c51d                	beqz	a0,80004eb8 <pipealloc+0xd6>
    fileclose(*f0);
    80004e8c:	00000097          	auipc	ra,0x0
    80004e90:	c26080e7          	jalr	-986(ra) # 80004ab2 <fileclose>
  if(*f1)
    80004e94:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e98:	557d                	li	a0,-1
  if(*f1)
    80004e9a:	c799                	beqz	a5,80004ea8 <pipealloc+0xc6>
    fileclose(*f1);
    80004e9c:	853e                	mv	a0,a5
    80004e9e:	00000097          	auipc	ra,0x0
    80004ea2:	c14080e7          	jalr	-1004(ra) # 80004ab2 <fileclose>
  return -1;
    80004ea6:	557d                	li	a0,-1
}
    80004ea8:	70a2                	ld	ra,40(sp)
    80004eaa:	7402                	ld	s0,32(sp)
    80004eac:	64e2                	ld	s1,24(sp)
    80004eae:	6942                	ld	s2,16(sp)
    80004eb0:	69a2                	ld	s3,8(sp)
    80004eb2:	6a02                	ld	s4,0(sp)
    80004eb4:	6145                	addi	sp,sp,48
    80004eb6:	8082                	ret
  return -1;
    80004eb8:	557d                	li	a0,-1
    80004eba:	b7fd                	j	80004ea8 <pipealloc+0xc6>

0000000080004ebc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ebc:	1101                	addi	sp,sp,-32
    80004ebe:	ec06                	sd	ra,24(sp)
    80004ec0:	e822                	sd	s0,16(sp)
    80004ec2:	e426                	sd	s1,8(sp)
    80004ec4:	e04a                	sd	s2,0(sp)
    80004ec6:	1000                	addi	s0,sp,32
    80004ec8:	84aa                	mv	s1,a0
    80004eca:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	d18080e7          	jalr	-744(ra) # 80000be4 <acquire>
  if(writable){
    80004ed4:	02090d63          	beqz	s2,80004f0e <pipeclose+0x52>
    pi->writeopen = 0;
    80004ed8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004edc:	21848513          	addi	a0,s1,536
    80004ee0:	ffffd097          	auipc	ra,0xffffd
    80004ee4:	2c2080e7          	jalr	706(ra) # 800021a2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ee8:	2204b783          	ld	a5,544(s1)
    80004eec:	eb95                	bnez	a5,80004f20 <pipeclose+0x64>
    release(&pi->lock);
    80004eee:	8526                	mv	a0,s1
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	da8080e7          	jalr	-600(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004ef8:	8526                	mv	a0,s1
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	afe080e7          	jalr	-1282(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004f02:	60e2                	ld	ra,24(sp)
    80004f04:	6442                	ld	s0,16(sp)
    80004f06:	64a2                	ld	s1,8(sp)
    80004f08:	6902                	ld	s2,0(sp)
    80004f0a:	6105                	addi	sp,sp,32
    80004f0c:	8082                	ret
    pi->readopen = 0;
    80004f0e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f12:	21c48513          	addi	a0,s1,540
    80004f16:	ffffd097          	auipc	ra,0xffffd
    80004f1a:	28c080e7          	jalr	652(ra) # 800021a2 <wakeup>
    80004f1e:	b7e9                	j	80004ee8 <pipeclose+0x2c>
    release(&pi->lock);
    80004f20:	8526                	mv	a0,s1
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	d76080e7          	jalr	-650(ra) # 80000c98 <release>
}
    80004f2a:	bfe1                	j	80004f02 <pipeclose+0x46>

0000000080004f2c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f2c:	7159                	addi	sp,sp,-112
    80004f2e:	f486                	sd	ra,104(sp)
    80004f30:	f0a2                	sd	s0,96(sp)
    80004f32:	eca6                	sd	s1,88(sp)
    80004f34:	e8ca                	sd	s2,80(sp)
    80004f36:	e4ce                	sd	s3,72(sp)
    80004f38:	e0d2                	sd	s4,64(sp)
    80004f3a:	fc56                	sd	s5,56(sp)
    80004f3c:	f85a                	sd	s6,48(sp)
    80004f3e:	f45e                	sd	s7,40(sp)
    80004f40:	f062                	sd	s8,32(sp)
    80004f42:	ec66                	sd	s9,24(sp)
    80004f44:	1880                	addi	s0,sp,112
    80004f46:	84aa                	mv	s1,a0
    80004f48:	8aae                	mv	s5,a1
    80004f4a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	a64080e7          	jalr	-1436(ra) # 800019b0 <myproc>
    80004f54:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f56:	8526                	mv	a0,s1
    80004f58:	ffffc097          	auipc	ra,0xffffc
    80004f5c:	c8c080e7          	jalr	-884(ra) # 80000be4 <acquire>
  while(i < n){
    80004f60:	0d405163          	blez	s4,80005022 <pipewrite+0xf6>
    80004f64:	8ba6                	mv	s7,s1
  int i = 0;
    80004f66:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f68:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f6a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f6e:	21c48c13          	addi	s8,s1,540
    80004f72:	a08d                	j	80004fd4 <pipewrite+0xa8>
      release(&pi->lock);
    80004f74:	8526                	mv	a0,s1
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	d22080e7          	jalr	-734(ra) # 80000c98 <release>
      return -1;
    80004f7e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f80:	854a                	mv	a0,s2
    80004f82:	70a6                	ld	ra,104(sp)
    80004f84:	7406                	ld	s0,96(sp)
    80004f86:	64e6                	ld	s1,88(sp)
    80004f88:	6946                	ld	s2,80(sp)
    80004f8a:	69a6                	ld	s3,72(sp)
    80004f8c:	6a06                	ld	s4,64(sp)
    80004f8e:	7ae2                	ld	s5,56(sp)
    80004f90:	7b42                	ld	s6,48(sp)
    80004f92:	7ba2                	ld	s7,40(sp)
    80004f94:	7c02                	ld	s8,32(sp)
    80004f96:	6ce2                	ld	s9,24(sp)
    80004f98:	6165                	addi	sp,sp,112
    80004f9a:	8082                	ret
      wakeup(&pi->nread);
    80004f9c:	8566                	mv	a0,s9
    80004f9e:	ffffd097          	auipc	ra,0xffffd
    80004fa2:	204080e7          	jalr	516(ra) # 800021a2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fa6:	85de                	mv	a1,s7
    80004fa8:	8562                	mv	a0,s8
    80004faa:	ffffd097          	auipc	ra,0xffffd
    80004fae:	06c080e7          	jalr	108(ra) # 80002016 <sleep>
    80004fb2:	a839                	j	80004fd0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fb4:	21c4a783          	lw	a5,540(s1)
    80004fb8:	0017871b          	addiw	a4,a5,1
    80004fbc:	20e4ae23          	sw	a4,540(s1)
    80004fc0:	1ff7f793          	andi	a5,a5,511
    80004fc4:	97a6                	add	a5,a5,s1
    80004fc6:	f9f44703          	lbu	a4,-97(s0)
    80004fca:	00e78c23          	sb	a4,24(a5)
      i++;
    80004fce:	2905                	addiw	s2,s2,1
  while(i < n){
    80004fd0:	03495d63          	bge	s2,s4,8000500a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004fd4:	2204a783          	lw	a5,544(s1)
    80004fd8:	dfd1                	beqz	a5,80004f74 <pipewrite+0x48>
    80004fda:	0289a783          	lw	a5,40(s3)
    80004fde:	fbd9                	bnez	a5,80004f74 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fe0:	2184a783          	lw	a5,536(s1)
    80004fe4:	21c4a703          	lw	a4,540(s1)
    80004fe8:	2007879b          	addiw	a5,a5,512
    80004fec:	faf708e3          	beq	a4,a5,80004f9c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ff0:	4685                	li	a3,1
    80004ff2:	01590633          	add	a2,s2,s5
    80004ff6:	f9f40593          	addi	a1,s0,-97
    80004ffa:	0709b503          	ld	a0,112(s3)
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	700080e7          	jalr	1792(ra) # 800016fe <copyin>
    80005006:	fb6517e3          	bne	a0,s6,80004fb4 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000500a:	21848513          	addi	a0,s1,536
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	194080e7          	jalr	404(ra) # 800021a2 <wakeup>
  release(&pi->lock);
    80005016:	8526                	mv	a0,s1
    80005018:	ffffc097          	auipc	ra,0xffffc
    8000501c:	c80080e7          	jalr	-896(ra) # 80000c98 <release>
  return i;
    80005020:	b785                	j	80004f80 <pipewrite+0x54>
  int i = 0;
    80005022:	4901                	li	s2,0
    80005024:	b7dd                	j	8000500a <pipewrite+0xde>

0000000080005026 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005026:	715d                	addi	sp,sp,-80
    80005028:	e486                	sd	ra,72(sp)
    8000502a:	e0a2                	sd	s0,64(sp)
    8000502c:	fc26                	sd	s1,56(sp)
    8000502e:	f84a                	sd	s2,48(sp)
    80005030:	f44e                	sd	s3,40(sp)
    80005032:	f052                	sd	s4,32(sp)
    80005034:	ec56                	sd	s5,24(sp)
    80005036:	e85a                	sd	s6,16(sp)
    80005038:	0880                	addi	s0,sp,80
    8000503a:	84aa                	mv	s1,a0
    8000503c:	892e                	mv	s2,a1
    8000503e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005040:	ffffd097          	auipc	ra,0xffffd
    80005044:	970080e7          	jalr	-1680(ra) # 800019b0 <myproc>
    80005048:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000504a:	8b26                	mv	s6,s1
    8000504c:	8526                	mv	a0,s1
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	b96080e7          	jalr	-1130(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005056:	2184a703          	lw	a4,536(s1)
    8000505a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000505e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005062:	02f71463          	bne	a4,a5,8000508a <piperead+0x64>
    80005066:	2244a783          	lw	a5,548(s1)
    8000506a:	c385                	beqz	a5,8000508a <piperead+0x64>
    if(pr->killed){
    8000506c:	028a2783          	lw	a5,40(s4)
    80005070:	ebc1                	bnez	a5,80005100 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005072:	85da                	mv	a1,s6
    80005074:	854e                	mv	a0,s3
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	fa0080e7          	jalr	-96(ra) # 80002016 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000507e:	2184a703          	lw	a4,536(s1)
    80005082:	21c4a783          	lw	a5,540(s1)
    80005086:	fef700e3          	beq	a4,a5,80005066 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000508a:	09505263          	blez	s5,8000510e <piperead+0xe8>
    8000508e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005090:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005092:	2184a783          	lw	a5,536(s1)
    80005096:	21c4a703          	lw	a4,540(s1)
    8000509a:	02f70d63          	beq	a4,a5,800050d4 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000509e:	0017871b          	addiw	a4,a5,1
    800050a2:	20e4ac23          	sw	a4,536(s1)
    800050a6:	1ff7f793          	andi	a5,a5,511
    800050aa:	97a6                	add	a5,a5,s1
    800050ac:	0187c783          	lbu	a5,24(a5)
    800050b0:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050b4:	4685                	li	a3,1
    800050b6:	fbf40613          	addi	a2,s0,-65
    800050ba:	85ca                	mv	a1,s2
    800050bc:	070a3503          	ld	a0,112(s4)
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	5b2080e7          	jalr	1458(ra) # 80001672 <copyout>
    800050c8:	01650663          	beq	a0,s6,800050d4 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050cc:	2985                	addiw	s3,s3,1
    800050ce:	0905                	addi	s2,s2,1
    800050d0:	fd3a91e3          	bne	s5,s3,80005092 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050d4:	21c48513          	addi	a0,s1,540
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	0ca080e7          	jalr	202(ra) # 800021a2 <wakeup>
  release(&pi->lock);
    800050e0:	8526                	mv	a0,s1
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	bb6080e7          	jalr	-1098(ra) # 80000c98 <release>
  return i;
}
    800050ea:	854e                	mv	a0,s3
    800050ec:	60a6                	ld	ra,72(sp)
    800050ee:	6406                	ld	s0,64(sp)
    800050f0:	74e2                	ld	s1,56(sp)
    800050f2:	7942                	ld	s2,48(sp)
    800050f4:	79a2                	ld	s3,40(sp)
    800050f6:	7a02                	ld	s4,32(sp)
    800050f8:	6ae2                	ld	s5,24(sp)
    800050fa:	6b42                	ld	s6,16(sp)
    800050fc:	6161                	addi	sp,sp,80
    800050fe:	8082                	ret
      release(&pi->lock);
    80005100:	8526                	mv	a0,s1
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	b96080e7          	jalr	-1130(ra) # 80000c98 <release>
      return -1;
    8000510a:	59fd                	li	s3,-1
    8000510c:	bff9                	j	800050ea <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000510e:	4981                	li	s3,0
    80005110:	b7d1                	j	800050d4 <piperead+0xae>

0000000080005112 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005112:	df010113          	addi	sp,sp,-528
    80005116:	20113423          	sd	ra,520(sp)
    8000511a:	20813023          	sd	s0,512(sp)
    8000511e:	ffa6                	sd	s1,504(sp)
    80005120:	fbca                	sd	s2,496(sp)
    80005122:	f7ce                	sd	s3,488(sp)
    80005124:	f3d2                	sd	s4,480(sp)
    80005126:	efd6                	sd	s5,472(sp)
    80005128:	ebda                	sd	s6,464(sp)
    8000512a:	e7de                	sd	s7,456(sp)
    8000512c:	e3e2                	sd	s8,448(sp)
    8000512e:	ff66                	sd	s9,440(sp)
    80005130:	fb6a                	sd	s10,432(sp)
    80005132:	f76e                	sd	s11,424(sp)
    80005134:	0c00                	addi	s0,sp,528
    80005136:	84aa                	mv	s1,a0
    80005138:	dea43c23          	sd	a0,-520(s0)
    8000513c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	870080e7          	jalr	-1936(ra) # 800019b0 <myproc>
    80005148:	892a                	mv	s2,a0

  begin_op();
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	49c080e7          	jalr	1180(ra) # 800045e6 <begin_op>

  if((ip = namei(path)) == 0){
    80005152:	8526                	mv	a0,s1
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	276080e7          	jalr	630(ra) # 800043ca <namei>
    8000515c:	c92d                	beqz	a0,800051ce <exec+0xbc>
    8000515e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	ab4080e7          	jalr	-1356(ra) # 80003c14 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005168:	04000713          	li	a4,64
    8000516c:	4681                	li	a3,0
    8000516e:	e5040613          	addi	a2,s0,-432
    80005172:	4581                	li	a1,0
    80005174:	8526                	mv	a0,s1
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	d52080e7          	jalr	-686(ra) # 80003ec8 <readi>
    8000517e:	04000793          	li	a5,64
    80005182:	00f51a63          	bne	a0,a5,80005196 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005186:	e5042703          	lw	a4,-432(s0)
    8000518a:	464c47b7          	lui	a5,0x464c4
    8000518e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005192:	04f70463          	beq	a4,a5,800051da <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005196:	8526                	mv	a0,s1
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	cde080e7          	jalr	-802(ra) # 80003e76 <iunlockput>
    end_op();
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	4c6080e7          	jalr	1222(ra) # 80004666 <end_op>
  }
  return -1;
    800051a8:	557d                	li	a0,-1
}
    800051aa:	20813083          	ld	ra,520(sp)
    800051ae:	20013403          	ld	s0,512(sp)
    800051b2:	74fe                	ld	s1,504(sp)
    800051b4:	795e                	ld	s2,496(sp)
    800051b6:	79be                	ld	s3,488(sp)
    800051b8:	7a1e                	ld	s4,480(sp)
    800051ba:	6afe                	ld	s5,472(sp)
    800051bc:	6b5e                	ld	s6,464(sp)
    800051be:	6bbe                	ld	s7,456(sp)
    800051c0:	6c1e                	ld	s8,448(sp)
    800051c2:	7cfa                	ld	s9,440(sp)
    800051c4:	7d5a                	ld	s10,432(sp)
    800051c6:	7dba                	ld	s11,424(sp)
    800051c8:	21010113          	addi	sp,sp,528
    800051cc:	8082                	ret
    end_op();
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	498080e7          	jalr	1176(ra) # 80004666 <end_op>
    return -1;
    800051d6:	557d                	li	a0,-1
    800051d8:	bfc9                	j	800051aa <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051da:	854a                	mv	a0,s2
    800051dc:	ffffd097          	auipc	ra,0xffffd
    800051e0:	898080e7          	jalr	-1896(ra) # 80001a74 <proc_pagetable>
    800051e4:	8baa                	mv	s7,a0
    800051e6:	d945                	beqz	a0,80005196 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051e8:	e7042983          	lw	s3,-400(s0)
    800051ec:	e8845783          	lhu	a5,-376(s0)
    800051f0:	c7ad                	beqz	a5,8000525a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051f2:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051f4:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800051f6:	6c85                	lui	s9,0x1
    800051f8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051fc:	def43823          	sd	a5,-528(s0)
    80005200:	a42d                	j	8000542a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005202:	00003517          	auipc	a0,0x3
    80005206:	5ee50513          	addi	a0,a0,1518 # 800087f0 <syscalls+0x298>
    8000520a:	ffffb097          	auipc	ra,0xffffb
    8000520e:	334080e7          	jalr	820(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005212:	8756                	mv	a4,s5
    80005214:	012d86bb          	addw	a3,s11,s2
    80005218:	4581                	li	a1,0
    8000521a:	8526                	mv	a0,s1
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	cac080e7          	jalr	-852(ra) # 80003ec8 <readi>
    80005224:	2501                	sext.w	a0,a0
    80005226:	1aaa9963          	bne	s5,a0,800053d8 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000522a:	6785                	lui	a5,0x1
    8000522c:	0127893b          	addw	s2,a5,s2
    80005230:	77fd                	lui	a5,0xfffff
    80005232:	01478a3b          	addw	s4,a5,s4
    80005236:	1f897163          	bgeu	s2,s8,80005418 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000523a:	02091593          	slli	a1,s2,0x20
    8000523e:	9181                	srli	a1,a1,0x20
    80005240:	95ea                	add	a1,a1,s10
    80005242:	855e                	mv	a0,s7
    80005244:	ffffc097          	auipc	ra,0xffffc
    80005248:	e2a080e7          	jalr	-470(ra) # 8000106e <walkaddr>
    8000524c:	862a                	mv	a2,a0
    if(pa == 0)
    8000524e:	d955                	beqz	a0,80005202 <exec+0xf0>
      n = PGSIZE;
    80005250:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005252:	fd9a70e3          	bgeu	s4,s9,80005212 <exec+0x100>
      n = sz - i;
    80005256:	8ad2                	mv	s5,s4
    80005258:	bf6d                	j	80005212 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000525a:	4901                	li	s2,0
  iunlockput(ip);
    8000525c:	8526                	mv	a0,s1
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	c18080e7          	jalr	-1000(ra) # 80003e76 <iunlockput>
  end_op();
    80005266:	fffff097          	auipc	ra,0xfffff
    8000526a:	400080e7          	jalr	1024(ra) # 80004666 <end_op>
  p = myproc();
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	742080e7          	jalr	1858(ra) # 800019b0 <myproc>
    80005276:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005278:	06853d03          	ld	s10,104(a0)
  sz = PGROUNDUP(sz);
    8000527c:	6785                	lui	a5,0x1
    8000527e:	17fd                	addi	a5,a5,-1
    80005280:	993e                	add	s2,s2,a5
    80005282:	757d                	lui	a0,0xfffff
    80005284:	00a977b3          	and	a5,s2,a0
    80005288:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000528c:	6609                	lui	a2,0x2
    8000528e:	963e                	add	a2,a2,a5
    80005290:	85be                	mv	a1,a5
    80005292:	855e                	mv	a0,s7
    80005294:	ffffc097          	auipc	ra,0xffffc
    80005298:	18e080e7          	jalr	398(ra) # 80001422 <uvmalloc>
    8000529c:	8b2a                	mv	s6,a0
  ip = 0;
    8000529e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800052a0:	12050c63          	beqz	a0,800053d8 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052a4:	75f9                	lui	a1,0xffffe
    800052a6:	95aa                	add	a1,a1,a0
    800052a8:	855e                	mv	a0,s7
    800052aa:	ffffc097          	auipc	ra,0xffffc
    800052ae:	396080e7          	jalr	918(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    800052b2:	7c7d                	lui	s8,0xfffff
    800052b4:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800052b6:	e0043783          	ld	a5,-512(s0)
    800052ba:	6388                	ld	a0,0(a5)
    800052bc:	c535                	beqz	a0,80005328 <exec+0x216>
    800052be:	e9040993          	addi	s3,s0,-368
    800052c2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052c6:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	b9c080e7          	jalr	-1124(ra) # 80000e64 <strlen>
    800052d0:	2505                	addiw	a0,a0,1
    800052d2:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052d6:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052da:	13896363          	bltu	s2,s8,80005400 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052de:	e0043d83          	ld	s11,-512(s0)
    800052e2:	000dba03          	ld	s4,0(s11)
    800052e6:	8552                	mv	a0,s4
    800052e8:	ffffc097          	auipc	ra,0xffffc
    800052ec:	b7c080e7          	jalr	-1156(ra) # 80000e64 <strlen>
    800052f0:	0015069b          	addiw	a3,a0,1
    800052f4:	8652                	mv	a2,s4
    800052f6:	85ca                	mv	a1,s2
    800052f8:	855e                	mv	a0,s7
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	378080e7          	jalr	888(ra) # 80001672 <copyout>
    80005302:	10054363          	bltz	a0,80005408 <exec+0x2f6>
    ustack[argc] = sp;
    80005306:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000530a:	0485                	addi	s1,s1,1
    8000530c:	008d8793          	addi	a5,s11,8
    80005310:	e0f43023          	sd	a5,-512(s0)
    80005314:	008db503          	ld	a0,8(s11)
    80005318:	c911                	beqz	a0,8000532c <exec+0x21a>
    if(argc >= MAXARG)
    8000531a:	09a1                	addi	s3,s3,8
    8000531c:	fb3c96e3          	bne	s9,s3,800052c8 <exec+0x1b6>
  sz = sz1;
    80005320:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005324:	4481                	li	s1,0
    80005326:	a84d                	j	800053d8 <exec+0x2c6>
  sp = sz;
    80005328:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000532a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000532c:	00349793          	slli	a5,s1,0x3
    80005330:	f9040713          	addi	a4,s0,-112
    80005334:	97ba                	add	a5,a5,a4
    80005336:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000533a:	00148693          	addi	a3,s1,1
    8000533e:	068e                	slli	a3,a3,0x3
    80005340:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005344:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005348:	01897663          	bgeu	s2,s8,80005354 <exec+0x242>
  sz = sz1;
    8000534c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005350:	4481                	li	s1,0
    80005352:	a059                	j	800053d8 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005354:	e9040613          	addi	a2,s0,-368
    80005358:	85ca                	mv	a1,s2
    8000535a:	855e                	mv	a0,s7
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	316080e7          	jalr	790(ra) # 80001672 <copyout>
    80005364:	0a054663          	bltz	a0,80005410 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005368:	078ab783          	ld	a5,120(s5)
    8000536c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005370:	df843783          	ld	a5,-520(s0)
    80005374:	0007c703          	lbu	a4,0(a5)
    80005378:	cf11                	beqz	a4,80005394 <exec+0x282>
    8000537a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000537c:	02f00693          	li	a3,47
    80005380:	a039                	j	8000538e <exec+0x27c>
      last = s+1;
    80005382:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005386:	0785                	addi	a5,a5,1
    80005388:	fff7c703          	lbu	a4,-1(a5)
    8000538c:	c701                	beqz	a4,80005394 <exec+0x282>
    if(*s == '/')
    8000538e:	fed71ce3          	bne	a4,a3,80005386 <exec+0x274>
    80005392:	bfc5                	j	80005382 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005394:	4641                	li	a2,16
    80005396:	df843583          	ld	a1,-520(s0)
    8000539a:	178a8513          	addi	a0,s5,376
    8000539e:	ffffc097          	auipc	ra,0xffffc
    800053a2:	a94080e7          	jalr	-1388(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    800053a6:	070ab503          	ld	a0,112(s5)
  p->pagetable = pagetable;
    800053aa:	077ab823          	sd	s7,112(s5)
  p->sz = sz;
    800053ae:	076ab423          	sd	s6,104(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053b2:	078ab783          	ld	a5,120(s5)
    800053b6:	e6843703          	ld	a4,-408(s0)
    800053ba:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053bc:	078ab783          	ld	a5,120(s5)
    800053c0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053c4:	85ea                	mv	a1,s10
    800053c6:	ffffc097          	auipc	ra,0xffffc
    800053ca:	74a080e7          	jalr	1866(ra) # 80001b10 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053ce:	0004851b          	sext.w	a0,s1
    800053d2:	bbe1                	j	800051aa <exec+0x98>
    800053d4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053d8:	e0843583          	ld	a1,-504(s0)
    800053dc:	855e                	mv	a0,s7
    800053de:	ffffc097          	auipc	ra,0xffffc
    800053e2:	732080e7          	jalr	1842(ra) # 80001b10 <proc_freepagetable>
  if(ip){
    800053e6:	da0498e3          	bnez	s1,80005196 <exec+0x84>
  return -1;
    800053ea:	557d                	li	a0,-1
    800053ec:	bb7d                	j	800051aa <exec+0x98>
    800053ee:	e1243423          	sd	s2,-504(s0)
    800053f2:	b7dd                	j	800053d8 <exec+0x2c6>
    800053f4:	e1243423          	sd	s2,-504(s0)
    800053f8:	b7c5                	j	800053d8 <exec+0x2c6>
    800053fa:	e1243423          	sd	s2,-504(s0)
    800053fe:	bfe9                	j	800053d8 <exec+0x2c6>
  sz = sz1;
    80005400:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005404:	4481                	li	s1,0
    80005406:	bfc9                	j	800053d8 <exec+0x2c6>
  sz = sz1;
    80005408:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000540c:	4481                	li	s1,0
    8000540e:	b7e9                	j	800053d8 <exec+0x2c6>
  sz = sz1;
    80005410:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005414:	4481                	li	s1,0
    80005416:	b7c9                	j	800053d8 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005418:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000541c:	2b05                	addiw	s6,s6,1
    8000541e:	0389899b          	addiw	s3,s3,56
    80005422:	e8845783          	lhu	a5,-376(s0)
    80005426:	e2fb5be3          	bge	s6,a5,8000525c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000542a:	2981                	sext.w	s3,s3
    8000542c:	03800713          	li	a4,56
    80005430:	86ce                	mv	a3,s3
    80005432:	e1840613          	addi	a2,s0,-488
    80005436:	4581                	li	a1,0
    80005438:	8526                	mv	a0,s1
    8000543a:	fffff097          	auipc	ra,0xfffff
    8000543e:	a8e080e7          	jalr	-1394(ra) # 80003ec8 <readi>
    80005442:	03800793          	li	a5,56
    80005446:	f8f517e3          	bne	a0,a5,800053d4 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000544a:	e1842783          	lw	a5,-488(s0)
    8000544e:	4705                	li	a4,1
    80005450:	fce796e3          	bne	a5,a4,8000541c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005454:	e4043603          	ld	a2,-448(s0)
    80005458:	e3843783          	ld	a5,-456(s0)
    8000545c:	f8f669e3          	bltu	a2,a5,800053ee <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005460:	e2843783          	ld	a5,-472(s0)
    80005464:	963e                	add	a2,a2,a5
    80005466:	f8f667e3          	bltu	a2,a5,800053f4 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000546a:	85ca                	mv	a1,s2
    8000546c:	855e                	mv	a0,s7
    8000546e:	ffffc097          	auipc	ra,0xffffc
    80005472:	fb4080e7          	jalr	-76(ra) # 80001422 <uvmalloc>
    80005476:	e0a43423          	sd	a0,-504(s0)
    8000547a:	d141                	beqz	a0,800053fa <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000547c:	e2843d03          	ld	s10,-472(s0)
    80005480:	df043783          	ld	a5,-528(s0)
    80005484:	00fd77b3          	and	a5,s10,a5
    80005488:	fba1                	bnez	a5,800053d8 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000548a:	e2042d83          	lw	s11,-480(s0)
    8000548e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005492:	f80c03e3          	beqz	s8,80005418 <exec+0x306>
    80005496:	8a62                	mv	s4,s8
    80005498:	4901                	li	s2,0
    8000549a:	b345                	j	8000523a <exec+0x128>

000000008000549c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000549c:	7179                	addi	sp,sp,-48
    8000549e:	f406                	sd	ra,40(sp)
    800054a0:	f022                	sd	s0,32(sp)
    800054a2:	ec26                	sd	s1,24(sp)
    800054a4:	e84a                	sd	s2,16(sp)
    800054a6:	1800                	addi	s0,sp,48
    800054a8:	892e                	mv	s2,a1
    800054aa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800054ac:	fdc40593          	addi	a1,s0,-36
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	b90080e7          	jalr	-1136(ra) # 80003040 <argint>
    800054b8:	04054063          	bltz	a0,800054f8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800054bc:	fdc42703          	lw	a4,-36(s0)
    800054c0:	47bd                	li	a5,15
    800054c2:	02e7ed63          	bltu	a5,a4,800054fc <argfd+0x60>
    800054c6:	ffffc097          	auipc	ra,0xffffc
    800054ca:	4ea080e7          	jalr	1258(ra) # 800019b0 <myproc>
    800054ce:	fdc42703          	lw	a4,-36(s0)
    800054d2:	01e70793          	addi	a5,a4,30
    800054d6:	078e                	slli	a5,a5,0x3
    800054d8:	953e                	add	a0,a0,a5
    800054da:	611c                	ld	a5,0(a0)
    800054dc:	c395                	beqz	a5,80005500 <argfd+0x64>
    return -1;
  if(pfd)
    800054de:	00090463          	beqz	s2,800054e6 <argfd+0x4a>
    *pfd = fd;
    800054e2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054e6:	4501                	li	a0,0
  if(pf)
    800054e8:	c091                	beqz	s1,800054ec <argfd+0x50>
    *pf = f;
    800054ea:	e09c                	sd	a5,0(s1)
}
    800054ec:	70a2                	ld	ra,40(sp)
    800054ee:	7402                	ld	s0,32(sp)
    800054f0:	64e2                	ld	s1,24(sp)
    800054f2:	6942                	ld	s2,16(sp)
    800054f4:	6145                	addi	sp,sp,48
    800054f6:	8082                	ret
    return -1;
    800054f8:	557d                	li	a0,-1
    800054fa:	bfcd                	j	800054ec <argfd+0x50>
    return -1;
    800054fc:	557d                	li	a0,-1
    800054fe:	b7fd                	j	800054ec <argfd+0x50>
    80005500:	557d                	li	a0,-1
    80005502:	b7ed                	j	800054ec <argfd+0x50>

0000000080005504 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005504:	1101                	addi	sp,sp,-32
    80005506:	ec06                	sd	ra,24(sp)
    80005508:	e822                	sd	s0,16(sp)
    8000550a:	e426                	sd	s1,8(sp)
    8000550c:	1000                	addi	s0,sp,32
    8000550e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005510:	ffffc097          	auipc	ra,0xffffc
    80005514:	4a0080e7          	jalr	1184(ra) # 800019b0 <myproc>
    80005518:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000551a:	0f050793          	addi	a5,a0,240 # fffffffffffff0f0 <end+0xffffffff7ffd90f0>
    8000551e:	4501                	li	a0,0
    80005520:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005522:	6398                	ld	a4,0(a5)
    80005524:	cb19                	beqz	a4,8000553a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005526:	2505                	addiw	a0,a0,1
    80005528:	07a1                	addi	a5,a5,8
    8000552a:	fed51ce3          	bne	a0,a3,80005522 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000552e:	557d                	li	a0,-1
}
    80005530:	60e2                	ld	ra,24(sp)
    80005532:	6442                	ld	s0,16(sp)
    80005534:	64a2                	ld	s1,8(sp)
    80005536:	6105                	addi	sp,sp,32
    80005538:	8082                	ret
      p->ofile[fd] = f;
    8000553a:	01e50793          	addi	a5,a0,30
    8000553e:	078e                	slli	a5,a5,0x3
    80005540:	963e                	add	a2,a2,a5
    80005542:	e204                	sd	s1,0(a2)
      return fd;
    80005544:	b7f5                	j	80005530 <fdalloc+0x2c>

0000000080005546 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005546:	715d                	addi	sp,sp,-80
    80005548:	e486                	sd	ra,72(sp)
    8000554a:	e0a2                	sd	s0,64(sp)
    8000554c:	fc26                	sd	s1,56(sp)
    8000554e:	f84a                	sd	s2,48(sp)
    80005550:	f44e                	sd	s3,40(sp)
    80005552:	f052                	sd	s4,32(sp)
    80005554:	ec56                	sd	s5,24(sp)
    80005556:	0880                	addi	s0,sp,80
    80005558:	89ae                	mv	s3,a1
    8000555a:	8ab2                	mv	s5,a2
    8000555c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000555e:	fb040593          	addi	a1,s0,-80
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	e86080e7          	jalr	-378(ra) # 800043e8 <nameiparent>
    8000556a:	892a                	mv	s2,a0
    8000556c:	12050f63          	beqz	a0,800056aa <create+0x164>
    return 0;

  ilock(dp);
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	6a4080e7          	jalr	1700(ra) # 80003c14 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005578:	4601                	li	a2,0
    8000557a:	fb040593          	addi	a1,s0,-80
    8000557e:	854a                	mv	a0,s2
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	b78080e7          	jalr	-1160(ra) # 800040f8 <dirlookup>
    80005588:	84aa                	mv	s1,a0
    8000558a:	c921                	beqz	a0,800055da <create+0x94>
    iunlockput(dp);
    8000558c:	854a                	mv	a0,s2
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	8e8080e7          	jalr	-1816(ra) # 80003e76 <iunlockput>
    ilock(ip);
    80005596:	8526                	mv	a0,s1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	67c080e7          	jalr	1660(ra) # 80003c14 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055a0:	2981                	sext.w	s3,s3
    800055a2:	4789                	li	a5,2
    800055a4:	02f99463          	bne	s3,a5,800055cc <create+0x86>
    800055a8:	0444d783          	lhu	a5,68(s1)
    800055ac:	37f9                	addiw	a5,a5,-2
    800055ae:	17c2                	slli	a5,a5,0x30
    800055b0:	93c1                	srli	a5,a5,0x30
    800055b2:	4705                	li	a4,1
    800055b4:	00f76c63          	bltu	a4,a5,800055cc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800055b8:	8526                	mv	a0,s1
    800055ba:	60a6                	ld	ra,72(sp)
    800055bc:	6406                	ld	s0,64(sp)
    800055be:	74e2                	ld	s1,56(sp)
    800055c0:	7942                	ld	s2,48(sp)
    800055c2:	79a2                	ld	s3,40(sp)
    800055c4:	7a02                	ld	s4,32(sp)
    800055c6:	6ae2                	ld	s5,24(sp)
    800055c8:	6161                	addi	sp,sp,80
    800055ca:	8082                	ret
    iunlockput(ip);
    800055cc:	8526                	mv	a0,s1
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	8a8080e7          	jalr	-1880(ra) # 80003e76 <iunlockput>
    return 0;
    800055d6:	4481                	li	s1,0
    800055d8:	b7c5                	j	800055b8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055da:	85ce                	mv	a1,s3
    800055dc:	00092503          	lw	a0,0(s2)
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	49c080e7          	jalr	1180(ra) # 80003a7c <ialloc>
    800055e8:	84aa                	mv	s1,a0
    800055ea:	c529                	beqz	a0,80005634 <create+0xee>
  ilock(ip);
    800055ec:	ffffe097          	auipc	ra,0xffffe
    800055f0:	628080e7          	jalr	1576(ra) # 80003c14 <ilock>
  ip->major = major;
    800055f4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800055f8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800055fc:	4785                	li	a5,1
    800055fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005602:	8526                	mv	a0,s1
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	546080e7          	jalr	1350(ra) # 80003b4a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000560c:	2981                	sext.w	s3,s3
    8000560e:	4785                	li	a5,1
    80005610:	02f98a63          	beq	s3,a5,80005644 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005614:	40d0                	lw	a2,4(s1)
    80005616:	fb040593          	addi	a1,s0,-80
    8000561a:	854a                	mv	a0,s2
    8000561c:	fffff097          	auipc	ra,0xfffff
    80005620:	cec080e7          	jalr	-788(ra) # 80004308 <dirlink>
    80005624:	06054b63          	bltz	a0,8000569a <create+0x154>
  iunlockput(dp);
    80005628:	854a                	mv	a0,s2
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	84c080e7          	jalr	-1972(ra) # 80003e76 <iunlockput>
  return ip;
    80005632:	b759                	j	800055b8 <create+0x72>
    panic("create: ialloc");
    80005634:	00003517          	auipc	a0,0x3
    80005638:	1dc50513          	addi	a0,a0,476 # 80008810 <syscalls+0x2b8>
    8000563c:	ffffb097          	auipc	ra,0xffffb
    80005640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    80005644:	04a95783          	lhu	a5,74(s2)
    80005648:	2785                	addiw	a5,a5,1
    8000564a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	4fa080e7          	jalr	1274(ra) # 80003b4a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005658:	40d0                	lw	a2,4(s1)
    8000565a:	00003597          	auipc	a1,0x3
    8000565e:	1c658593          	addi	a1,a1,454 # 80008820 <syscalls+0x2c8>
    80005662:	8526                	mv	a0,s1
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	ca4080e7          	jalr	-860(ra) # 80004308 <dirlink>
    8000566c:	00054f63          	bltz	a0,8000568a <create+0x144>
    80005670:	00492603          	lw	a2,4(s2)
    80005674:	00003597          	auipc	a1,0x3
    80005678:	1b458593          	addi	a1,a1,436 # 80008828 <syscalls+0x2d0>
    8000567c:	8526                	mv	a0,s1
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	c8a080e7          	jalr	-886(ra) # 80004308 <dirlink>
    80005686:	f80557e3          	bgez	a0,80005614 <create+0xce>
      panic("create dots");
    8000568a:	00003517          	auipc	a0,0x3
    8000568e:	1a650513          	addi	a0,a0,422 # 80008830 <syscalls+0x2d8>
    80005692:	ffffb097          	auipc	ra,0xffffb
    80005696:	eac080e7          	jalr	-340(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000569a:	00003517          	auipc	a0,0x3
    8000569e:	1a650513          	addi	a0,a0,422 # 80008840 <syscalls+0x2e8>
    800056a2:	ffffb097          	auipc	ra,0xffffb
    800056a6:	e9c080e7          	jalr	-356(ra) # 8000053e <panic>
    return 0;
    800056aa:	84aa                	mv	s1,a0
    800056ac:	b731                	j	800055b8 <create+0x72>

00000000800056ae <sys_dup>:
{
    800056ae:	7179                	addi	sp,sp,-48
    800056b0:	f406                	sd	ra,40(sp)
    800056b2:	f022                	sd	s0,32(sp)
    800056b4:	ec26                	sd	s1,24(sp)
    800056b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800056b8:	fd840613          	addi	a2,s0,-40
    800056bc:	4581                	li	a1,0
    800056be:	4501                	li	a0,0
    800056c0:	00000097          	auipc	ra,0x0
    800056c4:	ddc080e7          	jalr	-548(ra) # 8000549c <argfd>
    return -1;
    800056c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056ca:	02054363          	bltz	a0,800056f0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056ce:	fd843503          	ld	a0,-40(s0)
    800056d2:	00000097          	auipc	ra,0x0
    800056d6:	e32080e7          	jalr	-462(ra) # 80005504 <fdalloc>
    800056da:	84aa                	mv	s1,a0
    return -1;
    800056dc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056de:	00054963          	bltz	a0,800056f0 <sys_dup+0x42>
  filedup(f);
    800056e2:	fd843503          	ld	a0,-40(s0)
    800056e6:	fffff097          	auipc	ra,0xfffff
    800056ea:	37a080e7          	jalr	890(ra) # 80004a60 <filedup>
  return fd;
    800056ee:	87a6                	mv	a5,s1
}
    800056f0:	853e                	mv	a0,a5
    800056f2:	70a2                	ld	ra,40(sp)
    800056f4:	7402                	ld	s0,32(sp)
    800056f6:	64e2                	ld	s1,24(sp)
    800056f8:	6145                	addi	sp,sp,48
    800056fa:	8082                	ret

00000000800056fc <sys_read>:
{
    800056fc:	7179                	addi	sp,sp,-48
    800056fe:	f406                	sd	ra,40(sp)
    80005700:	f022                	sd	s0,32(sp)
    80005702:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005704:	fe840613          	addi	a2,s0,-24
    80005708:	4581                	li	a1,0
    8000570a:	4501                	li	a0,0
    8000570c:	00000097          	auipc	ra,0x0
    80005710:	d90080e7          	jalr	-624(ra) # 8000549c <argfd>
    return -1;
    80005714:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005716:	04054163          	bltz	a0,80005758 <sys_read+0x5c>
    8000571a:	fe440593          	addi	a1,s0,-28
    8000571e:	4509                	li	a0,2
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	920080e7          	jalr	-1760(ra) # 80003040 <argint>
    return -1;
    80005728:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000572a:	02054763          	bltz	a0,80005758 <sys_read+0x5c>
    8000572e:	fd840593          	addi	a1,s0,-40
    80005732:	4505                	li	a0,1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	92e080e7          	jalr	-1746(ra) # 80003062 <argaddr>
    return -1;
    8000573c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000573e:	00054d63          	bltz	a0,80005758 <sys_read+0x5c>
  return fileread(f, p, n);
    80005742:	fe442603          	lw	a2,-28(s0)
    80005746:	fd843583          	ld	a1,-40(s0)
    8000574a:	fe843503          	ld	a0,-24(s0)
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	49e080e7          	jalr	1182(ra) # 80004bec <fileread>
    80005756:	87aa                	mv	a5,a0
}
    80005758:	853e                	mv	a0,a5
    8000575a:	70a2                	ld	ra,40(sp)
    8000575c:	7402                	ld	s0,32(sp)
    8000575e:	6145                	addi	sp,sp,48
    80005760:	8082                	ret

0000000080005762 <sys_write>:
{
    80005762:	7179                	addi	sp,sp,-48
    80005764:	f406                	sd	ra,40(sp)
    80005766:	f022                	sd	s0,32(sp)
    80005768:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000576a:	fe840613          	addi	a2,s0,-24
    8000576e:	4581                	li	a1,0
    80005770:	4501                	li	a0,0
    80005772:	00000097          	auipc	ra,0x0
    80005776:	d2a080e7          	jalr	-726(ra) # 8000549c <argfd>
    return -1;
    8000577a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000577c:	04054163          	bltz	a0,800057be <sys_write+0x5c>
    80005780:	fe440593          	addi	a1,s0,-28
    80005784:	4509                	li	a0,2
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	8ba080e7          	jalr	-1862(ra) # 80003040 <argint>
    return -1;
    8000578e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005790:	02054763          	bltz	a0,800057be <sys_write+0x5c>
    80005794:	fd840593          	addi	a1,s0,-40
    80005798:	4505                	li	a0,1
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	8c8080e7          	jalr	-1848(ra) # 80003062 <argaddr>
    return -1;
    800057a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057a4:	00054d63          	bltz	a0,800057be <sys_write+0x5c>
  return filewrite(f, p, n);
    800057a8:	fe442603          	lw	a2,-28(s0)
    800057ac:	fd843583          	ld	a1,-40(s0)
    800057b0:	fe843503          	ld	a0,-24(s0)
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	4fa080e7          	jalr	1274(ra) # 80004cae <filewrite>
    800057bc:	87aa                	mv	a5,a0
}
    800057be:	853e                	mv	a0,a5
    800057c0:	70a2                	ld	ra,40(sp)
    800057c2:	7402                	ld	s0,32(sp)
    800057c4:	6145                	addi	sp,sp,48
    800057c6:	8082                	ret

00000000800057c8 <sys_close>:
{
    800057c8:	1101                	addi	sp,sp,-32
    800057ca:	ec06                	sd	ra,24(sp)
    800057cc:	e822                	sd	s0,16(sp)
    800057ce:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057d0:	fe040613          	addi	a2,s0,-32
    800057d4:	fec40593          	addi	a1,s0,-20
    800057d8:	4501                	li	a0,0
    800057da:	00000097          	auipc	ra,0x0
    800057de:	cc2080e7          	jalr	-830(ra) # 8000549c <argfd>
    return -1;
    800057e2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057e4:	02054463          	bltz	a0,8000580c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057e8:	ffffc097          	auipc	ra,0xffffc
    800057ec:	1c8080e7          	jalr	456(ra) # 800019b0 <myproc>
    800057f0:	fec42783          	lw	a5,-20(s0)
    800057f4:	07f9                	addi	a5,a5,30
    800057f6:	078e                	slli	a5,a5,0x3
    800057f8:	97aa                	add	a5,a5,a0
    800057fa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800057fe:	fe043503          	ld	a0,-32(s0)
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	2b0080e7          	jalr	688(ra) # 80004ab2 <fileclose>
  return 0;
    8000580a:	4781                	li	a5,0
}
    8000580c:	853e                	mv	a0,a5
    8000580e:	60e2                	ld	ra,24(sp)
    80005810:	6442                	ld	s0,16(sp)
    80005812:	6105                	addi	sp,sp,32
    80005814:	8082                	ret

0000000080005816 <sys_fstat>:
{
    80005816:	1101                	addi	sp,sp,-32
    80005818:	ec06                	sd	ra,24(sp)
    8000581a:	e822                	sd	s0,16(sp)
    8000581c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000581e:	fe840613          	addi	a2,s0,-24
    80005822:	4581                	li	a1,0
    80005824:	4501                	li	a0,0
    80005826:	00000097          	auipc	ra,0x0
    8000582a:	c76080e7          	jalr	-906(ra) # 8000549c <argfd>
    return -1;
    8000582e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005830:	02054563          	bltz	a0,8000585a <sys_fstat+0x44>
    80005834:	fe040593          	addi	a1,s0,-32
    80005838:	4505                	li	a0,1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	828080e7          	jalr	-2008(ra) # 80003062 <argaddr>
    return -1;
    80005842:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005844:	00054b63          	bltz	a0,8000585a <sys_fstat+0x44>
  return filestat(f, st);
    80005848:	fe043583          	ld	a1,-32(s0)
    8000584c:	fe843503          	ld	a0,-24(s0)
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	32a080e7          	jalr	810(ra) # 80004b7a <filestat>
    80005858:	87aa                	mv	a5,a0
}
    8000585a:	853e                	mv	a0,a5
    8000585c:	60e2                	ld	ra,24(sp)
    8000585e:	6442                	ld	s0,16(sp)
    80005860:	6105                	addi	sp,sp,32
    80005862:	8082                	ret

0000000080005864 <sys_link>:
{
    80005864:	7169                	addi	sp,sp,-304
    80005866:	f606                	sd	ra,296(sp)
    80005868:	f222                	sd	s0,288(sp)
    8000586a:	ee26                	sd	s1,280(sp)
    8000586c:	ea4a                	sd	s2,272(sp)
    8000586e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005870:	08000613          	li	a2,128
    80005874:	ed040593          	addi	a1,s0,-304
    80005878:	4501                	li	a0,0
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	80a080e7          	jalr	-2038(ra) # 80003084 <argstr>
    return -1;
    80005882:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005884:	10054e63          	bltz	a0,800059a0 <sys_link+0x13c>
    80005888:	08000613          	li	a2,128
    8000588c:	f5040593          	addi	a1,s0,-176
    80005890:	4505                	li	a0,1
    80005892:	ffffd097          	auipc	ra,0xffffd
    80005896:	7f2080e7          	jalr	2034(ra) # 80003084 <argstr>
    return -1;
    8000589a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000589c:	10054263          	bltz	a0,800059a0 <sys_link+0x13c>
  begin_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	d46080e7          	jalr	-698(ra) # 800045e6 <begin_op>
  if((ip = namei(old)) == 0){
    800058a8:	ed040513          	addi	a0,s0,-304
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	b1e080e7          	jalr	-1250(ra) # 800043ca <namei>
    800058b4:	84aa                	mv	s1,a0
    800058b6:	c551                	beqz	a0,80005942 <sys_link+0xde>
  ilock(ip);
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	35c080e7          	jalr	860(ra) # 80003c14 <ilock>
  if(ip->type == T_DIR){
    800058c0:	04449703          	lh	a4,68(s1)
    800058c4:	4785                	li	a5,1
    800058c6:	08f70463          	beq	a4,a5,8000594e <sys_link+0xea>
  ip->nlink++;
    800058ca:	04a4d783          	lhu	a5,74(s1)
    800058ce:	2785                	addiw	a5,a5,1
    800058d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058d4:	8526                	mv	a0,s1
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	274080e7          	jalr	628(ra) # 80003b4a <iupdate>
  iunlock(ip);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	3f6080e7          	jalr	1014(ra) # 80003cd6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058e8:	fd040593          	addi	a1,s0,-48
    800058ec:	f5040513          	addi	a0,s0,-176
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	af8080e7          	jalr	-1288(ra) # 800043e8 <nameiparent>
    800058f8:	892a                	mv	s2,a0
    800058fa:	c935                	beqz	a0,8000596e <sys_link+0x10a>
  ilock(dp);
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	318080e7          	jalr	792(ra) # 80003c14 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005904:	00092703          	lw	a4,0(s2)
    80005908:	409c                	lw	a5,0(s1)
    8000590a:	04f71d63          	bne	a4,a5,80005964 <sys_link+0x100>
    8000590e:	40d0                	lw	a2,4(s1)
    80005910:	fd040593          	addi	a1,s0,-48
    80005914:	854a                	mv	a0,s2
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	9f2080e7          	jalr	-1550(ra) # 80004308 <dirlink>
    8000591e:	04054363          	bltz	a0,80005964 <sys_link+0x100>
  iunlockput(dp);
    80005922:	854a                	mv	a0,s2
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	552080e7          	jalr	1362(ra) # 80003e76 <iunlockput>
  iput(ip);
    8000592c:	8526                	mv	a0,s1
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	4a0080e7          	jalr	1184(ra) # 80003dce <iput>
  end_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	d30080e7          	jalr	-720(ra) # 80004666 <end_op>
  return 0;
    8000593e:	4781                	li	a5,0
    80005940:	a085                	j	800059a0 <sys_link+0x13c>
    end_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	d24080e7          	jalr	-732(ra) # 80004666 <end_op>
    return -1;
    8000594a:	57fd                	li	a5,-1
    8000594c:	a891                	j	800059a0 <sys_link+0x13c>
    iunlockput(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	526080e7          	jalr	1318(ra) # 80003e76 <iunlockput>
    end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	d0e080e7          	jalr	-754(ra) # 80004666 <end_op>
    return -1;
    80005960:	57fd                	li	a5,-1
    80005962:	a83d                	j	800059a0 <sys_link+0x13c>
    iunlockput(dp);
    80005964:	854a                	mv	a0,s2
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	510080e7          	jalr	1296(ra) # 80003e76 <iunlockput>
  ilock(ip);
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	2a4080e7          	jalr	676(ra) # 80003c14 <ilock>
  ip->nlink--;
    80005978:	04a4d783          	lhu	a5,74(s1)
    8000597c:	37fd                	addiw	a5,a5,-1
    8000597e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005982:	8526                	mv	a0,s1
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	1c6080e7          	jalr	454(ra) # 80003b4a <iupdate>
  iunlockput(ip);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	4e8080e7          	jalr	1256(ra) # 80003e76 <iunlockput>
  end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	cd0080e7          	jalr	-816(ra) # 80004666 <end_op>
  return -1;
    8000599e:	57fd                	li	a5,-1
}
    800059a0:	853e                	mv	a0,a5
    800059a2:	70b2                	ld	ra,296(sp)
    800059a4:	7412                	ld	s0,288(sp)
    800059a6:	64f2                	ld	s1,280(sp)
    800059a8:	6952                	ld	s2,272(sp)
    800059aa:	6155                	addi	sp,sp,304
    800059ac:	8082                	ret

00000000800059ae <sys_unlink>:
{
    800059ae:	7151                	addi	sp,sp,-240
    800059b0:	f586                	sd	ra,232(sp)
    800059b2:	f1a2                	sd	s0,224(sp)
    800059b4:	eda6                	sd	s1,216(sp)
    800059b6:	e9ca                	sd	s2,208(sp)
    800059b8:	e5ce                	sd	s3,200(sp)
    800059ba:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800059bc:	08000613          	li	a2,128
    800059c0:	f3040593          	addi	a1,s0,-208
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	6be080e7          	jalr	1726(ra) # 80003084 <argstr>
    800059ce:	18054163          	bltz	a0,80005b50 <sys_unlink+0x1a2>
  begin_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	c14080e7          	jalr	-1004(ra) # 800045e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059da:	fb040593          	addi	a1,s0,-80
    800059de:	f3040513          	addi	a0,s0,-208
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	a06080e7          	jalr	-1530(ra) # 800043e8 <nameiparent>
    800059ea:	84aa                	mv	s1,a0
    800059ec:	c979                	beqz	a0,80005ac2 <sys_unlink+0x114>
  ilock(dp);
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	226080e7          	jalr	550(ra) # 80003c14 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059f6:	00003597          	auipc	a1,0x3
    800059fa:	e2a58593          	addi	a1,a1,-470 # 80008820 <syscalls+0x2c8>
    800059fe:	fb040513          	addi	a0,s0,-80
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	6dc080e7          	jalr	1756(ra) # 800040de <namecmp>
    80005a0a:	14050a63          	beqz	a0,80005b5e <sys_unlink+0x1b0>
    80005a0e:	00003597          	auipc	a1,0x3
    80005a12:	e1a58593          	addi	a1,a1,-486 # 80008828 <syscalls+0x2d0>
    80005a16:	fb040513          	addi	a0,s0,-80
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	6c4080e7          	jalr	1732(ra) # 800040de <namecmp>
    80005a22:	12050e63          	beqz	a0,80005b5e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a26:	f2c40613          	addi	a2,s0,-212
    80005a2a:	fb040593          	addi	a1,s0,-80
    80005a2e:	8526                	mv	a0,s1
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	6c8080e7          	jalr	1736(ra) # 800040f8 <dirlookup>
    80005a38:	892a                	mv	s2,a0
    80005a3a:	12050263          	beqz	a0,80005b5e <sys_unlink+0x1b0>
  ilock(ip);
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	1d6080e7          	jalr	470(ra) # 80003c14 <ilock>
  if(ip->nlink < 1)
    80005a46:	04a91783          	lh	a5,74(s2)
    80005a4a:	08f05263          	blez	a5,80005ace <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a4e:	04491703          	lh	a4,68(s2)
    80005a52:	4785                	li	a5,1
    80005a54:	08f70563          	beq	a4,a5,80005ade <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a58:	4641                	li	a2,16
    80005a5a:	4581                	li	a1,0
    80005a5c:	fc040513          	addi	a0,s0,-64
    80005a60:	ffffb097          	auipc	ra,0xffffb
    80005a64:	280080e7          	jalr	640(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a68:	4741                	li	a4,16
    80005a6a:	f2c42683          	lw	a3,-212(s0)
    80005a6e:	fc040613          	addi	a2,s0,-64
    80005a72:	4581                	li	a1,0
    80005a74:	8526                	mv	a0,s1
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	54a080e7          	jalr	1354(ra) # 80003fc0 <writei>
    80005a7e:	47c1                	li	a5,16
    80005a80:	0af51563          	bne	a0,a5,80005b2a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a84:	04491703          	lh	a4,68(s2)
    80005a88:	4785                	li	a5,1
    80005a8a:	0af70863          	beq	a4,a5,80005b3a <sys_unlink+0x18c>
  iunlockput(dp);
    80005a8e:	8526                	mv	a0,s1
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	3e6080e7          	jalr	998(ra) # 80003e76 <iunlockput>
  ip->nlink--;
    80005a98:	04a95783          	lhu	a5,74(s2)
    80005a9c:	37fd                	addiw	a5,a5,-1
    80005a9e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005aa2:	854a                	mv	a0,s2
    80005aa4:	ffffe097          	auipc	ra,0xffffe
    80005aa8:	0a6080e7          	jalr	166(ra) # 80003b4a <iupdate>
  iunlockput(ip);
    80005aac:	854a                	mv	a0,s2
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	3c8080e7          	jalr	968(ra) # 80003e76 <iunlockput>
  end_op();
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	bb0080e7          	jalr	-1104(ra) # 80004666 <end_op>
  return 0;
    80005abe:	4501                	li	a0,0
    80005ac0:	a84d                	j	80005b72 <sys_unlink+0x1c4>
    end_op();
    80005ac2:	fffff097          	auipc	ra,0xfffff
    80005ac6:	ba4080e7          	jalr	-1116(ra) # 80004666 <end_op>
    return -1;
    80005aca:	557d                	li	a0,-1
    80005acc:	a05d                	j	80005b72 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ace:	00003517          	auipc	a0,0x3
    80005ad2:	d8250513          	addi	a0,a0,-638 # 80008850 <syscalls+0x2f8>
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	a68080e7          	jalr	-1432(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ade:	04c92703          	lw	a4,76(s2)
    80005ae2:	02000793          	li	a5,32
    80005ae6:	f6e7f9e3          	bgeu	a5,a4,80005a58 <sys_unlink+0xaa>
    80005aea:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aee:	4741                	li	a4,16
    80005af0:	86ce                	mv	a3,s3
    80005af2:	f1840613          	addi	a2,s0,-232
    80005af6:	4581                	li	a1,0
    80005af8:	854a                	mv	a0,s2
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	3ce080e7          	jalr	974(ra) # 80003ec8 <readi>
    80005b02:	47c1                	li	a5,16
    80005b04:	00f51b63          	bne	a0,a5,80005b1a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b08:	f1845783          	lhu	a5,-232(s0)
    80005b0c:	e7a1                	bnez	a5,80005b54 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b0e:	29c1                	addiw	s3,s3,16
    80005b10:	04c92783          	lw	a5,76(s2)
    80005b14:	fcf9ede3          	bltu	s3,a5,80005aee <sys_unlink+0x140>
    80005b18:	b781                	j	80005a58 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b1a:	00003517          	auipc	a0,0x3
    80005b1e:	d4e50513          	addi	a0,a0,-690 # 80008868 <syscalls+0x310>
    80005b22:	ffffb097          	auipc	ra,0xffffb
    80005b26:	a1c080e7          	jalr	-1508(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005b2a:	00003517          	auipc	a0,0x3
    80005b2e:	d5650513          	addi	a0,a0,-682 # 80008880 <syscalls+0x328>
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	a0c080e7          	jalr	-1524(ra) # 8000053e <panic>
    dp->nlink--;
    80005b3a:	04a4d783          	lhu	a5,74(s1)
    80005b3e:	37fd                	addiw	a5,a5,-1
    80005b40:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b44:	8526                	mv	a0,s1
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	004080e7          	jalr	4(ra) # 80003b4a <iupdate>
    80005b4e:	b781                	j	80005a8e <sys_unlink+0xe0>
    return -1;
    80005b50:	557d                	li	a0,-1
    80005b52:	a005                	j	80005b72 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b54:	854a                	mv	a0,s2
    80005b56:	ffffe097          	auipc	ra,0xffffe
    80005b5a:	320080e7          	jalr	800(ra) # 80003e76 <iunlockput>
  iunlockput(dp);
    80005b5e:	8526                	mv	a0,s1
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	316080e7          	jalr	790(ra) # 80003e76 <iunlockput>
  end_op();
    80005b68:	fffff097          	auipc	ra,0xfffff
    80005b6c:	afe080e7          	jalr	-1282(ra) # 80004666 <end_op>
  return -1;
    80005b70:	557d                	li	a0,-1
}
    80005b72:	70ae                	ld	ra,232(sp)
    80005b74:	740e                	ld	s0,224(sp)
    80005b76:	64ee                	ld	s1,216(sp)
    80005b78:	694e                	ld	s2,208(sp)
    80005b7a:	69ae                	ld	s3,200(sp)
    80005b7c:	616d                	addi	sp,sp,240
    80005b7e:	8082                	ret

0000000080005b80 <sys_open>:

uint64
sys_open(void)
{
    80005b80:	7131                	addi	sp,sp,-192
    80005b82:	fd06                	sd	ra,184(sp)
    80005b84:	f922                	sd	s0,176(sp)
    80005b86:	f526                	sd	s1,168(sp)
    80005b88:	f14a                	sd	s2,160(sp)
    80005b8a:	ed4e                	sd	s3,152(sp)
    80005b8c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b8e:	08000613          	li	a2,128
    80005b92:	f5040593          	addi	a1,s0,-176
    80005b96:	4501                	li	a0,0
    80005b98:	ffffd097          	auipc	ra,0xffffd
    80005b9c:	4ec080e7          	jalr	1260(ra) # 80003084 <argstr>
    return -1;
    80005ba0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ba2:	0c054163          	bltz	a0,80005c64 <sys_open+0xe4>
    80005ba6:	f4c40593          	addi	a1,s0,-180
    80005baa:	4505                	li	a0,1
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	494080e7          	jalr	1172(ra) # 80003040 <argint>
    80005bb4:	0a054863          	bltz	a0,80005c64 <sys_open+0xe4>

  begin_op();
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	a2e080e7          	jalr	-1490(ra) # 800045e6 <begin_op>

  if(omode & O_CREATE){
    80005bc0:	f4c42783          	lw	a5,-180(s0)
    80005bc4:	2007f793          	andi	a5,a5,512
    80005bc8:	cbdd                	beqz	a5,80005c7e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005bca:	4681                	li	a3,0
    80005bcc:	4601                	li	a2,0
    80005bce:	4589                	li	a1,2
    80005bd0:	f5040513          	addi	a0,s0,-176
    80005bd4:	00000097          	auipc	ra,0x0
    80005bd8:	972080e7          	jalr	-1678(ra) # 80005546 <create>
    80005bdc:	892a                	mv	s2,a0
    if(ip == 0){
    80005bde:	c959                	beqz	a0,80005c74 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005be0:	04491703          	lh	a4,68(s2)
    80005be4:	478d                	li	a5,3
    80005be6:	00f71763          	bne	a4,a5,80005bf4 <sys_open+0x74>
    80005bea:	04695703          	lhu	a4,70(s2)
    80005bee:	47a5                	li	a5,9
    80005bf0:	0ce7ec63          	bltu	a5,a4,80005cc8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	e02080e7          	jalr	-510(ra) # 800049f6 <filealloc>
    80005bfc:	89aa                	mv	s3,a0
    80005bfe:	10050263          	beqz	a0,80005d02 <sys_open+0x182>
    80005c02:	00000097          	auipc	ra,0x0
    80005c06:	902080e7          	jalr	-1790(ra) # 80005504 <fdalloc>
    80005c0a:	84aa                	mv	s1,a0
    80005c0c:	0e054663          	bltz	a0,80005cf8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c10:	04491703          	lh	a4,68(s2)
    80005c14:	478d                	li	a5,3
    80005c16:	0cf70463          	beq	a4,a5,80005cde <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c1a:	4789                	li	a5,2
    80005c1c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c20:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c24:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c28:	f4c42783          	lw	a5,-180(s0)
    80005c2c:	0017c713          	xori	a4,a5,1
    80005c30:	8b05                	andi	a4,a4,1
    80005c32:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c36:	0037f713          	andi	a4,a5,3
    80005c3a:	00e03733          	snez	a4,a4
    80005c3e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c42:	4007f793          	andi	a5,a5,1024
    80005c46:	c791                	beqz	a5,80005c52 <sys_open+0xd2>
    80005c48:	04491703          	lh	a4,68(s2)
    80005c4c:	4789                	li	a5,2
    80005c4e:	08f70f63          	beq	a4,a5,80005cec <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c52:	854a                	mv	a0,s2
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	082080e7          	jalr	130(ra) # 80003cd6 <iunlock>
  end_op();
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	a0a080e7          	jalr	-1526(ra) # 80004666 <end_op>

  return fd;
}
    80005c64:	8526                	mv	a0,s1
    80005c66:	70ea                	ld	ra,184(sp)
    80005c68:	744a                	ld	s0,176(sp)
    80005c6a:	74aa                	ld	s1,168(sp)
    80005c6c:	790a                	ld	s2,160(sp)
    80005c6e:	69ea                	ld	s3,152(sp)
    80005c70:	6129                	addi	sp,sp,192
    80005c72:	8082                	ret
      end_op();
    80005c74:	fffff097          	auipc	ra,0xfffff
    80005c78:	9f2080e7          	jalr	-1550(ra) # 80004666 <end_op>
      return -1;
    80005c7c:	b7e5                	j	80005c64 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c7e:	f5040513          	addi	a0,s0,-176
    80005c82:	ffffe097          	auipc	ra,0xffffe
    80005c86:	748080e7          	jalr	1864(ra) # 800043ca <namei>
    80005c8a:	892a                	mv	s2,a0
    80005c8c:	c905                	beqz	a0,80005cbc <sys_open+0x13c>
    ilock(ip);
    80005c8e:	ffffe097          	auipc	ra,0xffffe
    80005c92:	f86080e7          	jalr	-122(ra) # 80003c14 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c96:	04491703          	lh	a4,68(s2)
    80005c9a:	4785                	li	a5,1
    80005c9c:	f4f712e3          	bne	a4,a5,80005be0 <sys_open+0x60>
    80005ca0:	f4c42783          	lw	a5,-180(s0)
    80005ca4:	dba1                	beqz	a5,80005bf4 <sys_open+0x74>
      iunlockput(ip);
    80005ca6:	854a                	mv	a0,s2
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	1ce080e7          	jalr	462(ra) # 80003e76 <iunlockput>
      end_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	9b6080e7          	jalr	-1610(ra) # 80004666 <end_op>
      return -1;
    80005cb8:	54fd                	li	s1,-1
    80005cba:	b76d                	j	80005c64 <sys_open+0xe4>
      end_op();
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	9aa080e7          	jalr	-1622(ra) # 80004666 <end_op>
      return -1;
    80005cc4:	54fd                	li	s1,-1
    80005cc6:	bf79                	j	80005c64 <sys_open+0xe4>
    iunlockput(ip);
    80005cc8:	854a                	mv	a0,s2
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	1ac080e7          	jalr	428(ra) # 80003e76 <iunlockput>
    end_op();
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	994080e7          	jalr	-1644(ra) # 80004666 <end_op>
    return -1;
    80005cda:	54fd                	li	s1,-1
    80005cdc:	b761                	j	80005c64 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cde:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ce2:	04691783          	lh	a5,70(s2)
    80005ce6:	02f99223          	sh	a5,36(s3)
    80005cea:	bf2d                	j	80005c24 <sys_open+0xa4>
    itrunc(ip);
    80005cec:	854a                	mv	a0,s2
    80005cee:	ffffe097          	auipc	ra,0xffffe
    80005cf2:	034080e7          	jalr	52(ra) # 80003d22 <itrunc>
    80005cf6:	bfb1                	j	80005c52 <sys_open+0xd2>
      fileclose(f);
    80005cf8:	854e                	mv	a0,s3
    80005cfa:	fffff097          	auipc	ra,0xfffff
    80005cfe:	db8080e7          	jalr	-584(ra) # 80004ab2 <fileclose>
    iunlockput(ip);
    80005d02:	854a                	mv	a0,s2
    80005d04:	ffffe097          	auipc	ra,0xffffe
    80005d08:	172080e7          	jalr	370(ra) # 80003e76 <iunlockput>
    end_op();
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	95a080e7          	jalr	-1702(ra) # 80004666 <end_op>
    return -1;
    80005d14:	54fd                	li	s1,-1
    80005d16:	b7b9                	j	80005c64 <sys_open+0xe4>

0000000080005d18 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d18:	7175                	addi	sp,sp,-144
    80005d1a:	e506                	sd	ra,136(sp)
    80005d1c:	e122                	sd	s0,128(sp)
    80005d1e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d20:	fffff097          	auipc	ra,0xfffff
    80005d24:	8c6080e7          	jalr	-1850(ra) # 800045e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d28:	08000613          	li	a2,128
    80005d2c:	f7040593          	addi	a1,s0,-144
    80005d30:	4501                	li	a0,0
    80005d32:	ffffd097          	auipc	ra,0xffffd
    80005d36:	352080e7          	jalr	850(ra) # 80003084 <argstr>
    80005d3a:	02054963          	bltz	a0,80005d6c <sys_mkdir+0x54>
    80005d3e:	4681                	li	a3,0
    80005d40:	4601                	li	a2,0
    80005d42:	4585                	li	a1,1
    80005d44:	f7040513          	addi	a0,s0,-144
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	7fe080e7          	jalr	2046(ra) # 80005546 <create>
    80005d50:	cd11                	beqz	a0,80005d6c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	124080e7          	jalr	292(ra) # 80003e76 <iunlockput>
  end_op();
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	90c080e7          	jalr	-1780(ra) # 80004666 <end_op>
  return 0;
    80005d62:	4501                	li	a0,0
}
    80005d64:	60aa                	ld	ra,136(sp)
    80005d66:	640a                	ld	s0,128(sp)
    80005d68:	6149                	addi	sp,sp,144
    80005d6a:	8082                	ret
    end_op();
    80005d6c:	fffff097          	auipc	ra,0xfffff
    80005d70:	8fa080e7          	jalr	-1798(ra) # 80004666 <end_op>
    return -1;
    80005d74:	557d                	li	a0,-1
    80005d76:	b7fd                	j	80005d64 <sys_mkdir+0x4c>

0000000080005d78 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d78:	7135                	addi	sp,sp,-160
    80005d7a:	ed06                	sd	ra,152(sp)
    80005d7c:	e922                	sd	s0,144(sp)
    80005d7e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	866080e7          	jalr	-1946(ra) # 800045e6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d88:	08000613          	li	a2,128
    80005d8c:	f7040593          	addi	a1,s0,-144
    80005d90:	4501                	li	a0,0
    80005d92:	ffffd097          	auipc	ra,0xffffd
    80005d96:	2f2080e7          	jalr	754(ra) # 80003084 <argstr>
    80005d9a:	04054a63          	bltz	a0,80005dee <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d9e:	f6c40593          	addi	a1,s0,-148
    80005da2:	4505                	li	a0,1
    80005da4:	ffffd097          	auipc	ra,0xffffd
    80005da8:	29c080e7          	jalr	668(ra) # 80003040 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005dac:	04054163          	bltz	a0,80005dee <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005db0:	f6840593          	addi	a1,s0,-152
    80005db4:	4509                	li	a0,2
    80005db6:	ffffd097          	auipc	ra,0xffffd
    80005dba:	28a080e7          	jalr	650(ra) # 80003040 <argint>
     argint(1, &major) < 0 ||
    80005dbe:	02054863          	bltz	a0,80005dee <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dc2:	f6841683          	lh	a3,-152(s0)
    80005dc6:	f6c41603          	lh	a2,-148(s0)
    80005dca:	458d                	li	a1,3
    80005dcc:	f7040513          	addi	a0,s0,-144
    80005dd0:	fffff097          	auipc	ra,0xfffff
    80005dd4:	776080e7          	jalr	1910(ra) # 80005546 <create>
     argint(2, &minor) < 0 ||
    80005dd8:	c919                	beqz	a0,80005dee <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	09c080e7          	jalr	156(ra) # 80003e76 <iunlockput>
  end_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	884080e7          	jalr	-1916(ra) # 80004666 <end_op>
  return 0;
    80005dea:	4501                	li	a0,0
    80005dec:	a031                	j	80005df8 <sys_mknod+0x80>
    end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	878080e7          	jalr	-1928(ra) # 80004666 <end_op>
    return -1;
    80005df6:	557d                	li	a0,-1
}
    80005df8:	60ea                	ld	ra,152(sp)
    80005dfa:	644a                	ld	s0,144(sp)
    80005dfc:	610d                	addi	sp,sp,160
    80005dfe:	8082                	ret

0000000080005e00 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e00:	7135                	addi	sp,sp,-160
    80005e02:	ed06                	sd	ra,152(sp)
    80005e04:	e922                	sd	s0,144(sp)
    80005e06:	e526                	sd	s1,136(sp)
    80005e08:	e14a                	sd	s2,128(sp)
    80005e0a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e0c:	ffffc097          	auipc	ra,0xffffc
    80005e10:	ba4080e7          	jalr	-1116(ra) # 800019b0 <myproc>
    80005e14:	892a                	mv	s2,a0
  
  begin_op();
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	7d0080e7          	jalr	2000(ra) # 800045e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e1e:	08000613          	li	a2,128
    80005e22:	f6040593          	addi	a1,s0,-160
    80005e26:	4501                	li	a0,0
    80005e28:	ffffd097          	auipc	ra,0xffffd
    80005e2c:	25c080e7          	jalr	604(ra) # 80003084 <argstr>
    80005e30:	04054b63          	bltz	a0,80005e86 <sys_chdir+0x86>
    80005e34:	f6040513          	addi	a0,s0,-160
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	592080e7          	jalr	1426(ra) # 800043ca <namei>
    80005e40:	84aa                	mv	s1,a0
    80005e42:	c131                	beqz	a0,80005e86 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e44:	ffffe097          	auipc	ra,0xffffe
    80005e48:	dd0080e7          	jalr	-560(ra) # 80003c14 <ilock>
  if(ip->type != T_DIR){
    80005e4c:	04449703          	lh	a4,68(s1)
    80005e50:	4785                	li	a5,1
    80005e52:	04f71063          	bne	a4,a5,80005e92 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e56:	8526                	mv	a0,s1
    80005e58:	ffffe097          	auipc	ra,0xffffe
    80005e5c:	e7e080e7          	jalr	-386(ra) # 80003cd6 <iunlock>
  iput(p->cwd);
    80005e60:	17093503          	ld	a0,368(s2)
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	f6a080e7          	jalr	-150(ra) # 80003dce <iput>
  end_op();
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	7fa080e7          	jalr	2042(ra) # 80004666 <end_op>
  p->cwd = ip;
    80005e74:	16993823          	sd	s1,368(s2)
  return 0;
    80005e78:	4501                	li	a0,0
}
    80005e7a:	60ea                	ld	ra,152(sp)
    80005e7c:	644a                	ld	s0,144(sp)
    80005e7e:	64aa                	ld	s1,136(sp)
    80005e80:	690a                	ld	s2,128(sp)
    80005e82:	610d                	addi	sp,sp,160
    80005e84:	8082                	ret
    end_op();
    80005e86:	ffffe097          	auipc	ra,0xffffe
    80005e8a:	7e0080e7          	jalr	2016(ra) # 80004666 <end_op>
    return -1;
    80005e8e:	557d                	li	a0,-1
    80005e90:	b7ed                	j	80005e7a <sys_chdir+0x7a>
    iunlockput(ip);
    80005e92:	8526                	mv	a0,s1
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	fe2080e7          	jalr	-30(ra) # 80003e76 <iunlockput>
    end_op();
    80005e9c:	ffffe097          	auipc	ra,0xffffe
    80005ea0:	7ca080e7          	jalr	1994(ra) # 80004666 <end_op>
    return -1;
    80005ea4:	557d                	li	a0,-1
    80005ea6:	bfd1                	j	80005e7a <sys_chdir+0x7a>

0000000080005ea8 <sys_exec>:

uint64
sys_exec(void)
{
    80005ea8:	7145                	addi	sp,sp,-464
    80005eaa:	e786                	sd	ra,456(sp)
    80005eac:	e3a2                	sd	s0,448(sp)
    80005eae:	ff26                	sd	s1,440(sp)
    80005eb0:	fb4a                	sd	s2,432(sp)
    80005eb2:	f74e                	sd	s3,424(sp)
    80005eb4:	f352                	sd	s4,416(sp)
    80005eb6:	ef56                	sd	s5,408(sp)
    80005eb8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005eba:	08000613          	li	a2,128
    80005ebe:	f4040593          	addi	a1,s0,-192
    80005ec2:	4501                	li	a0,0
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	1c0080e7          	jalr	448(ra) # 80003084 <argstr>
    return -1;
    80005ecc:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ece:	0c054a63          	bltz	a0,80005fa2 <sys_exec+0xfa>
    80005ed2:	e3840593          	addi	a1,s0,-456
    80005ed6:	4505                	li	a0,1
    80005ed8:	ffffd097          	auipc	ra,0xffffd
    80005edc:	18a080e7          	jalr	394(ra) # 80003062 <argaddr>
    80005ee0:	0c054163          	bltz	a0,80005fa2 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ee4:	10000613          	li	a2,256
    80005ee8:	4581                	li	a1,0
    80005eea:	e4040513          	addi	a0,s0,-448
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	df2080e7          	jalr	-526(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ef6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005efa:	89a6                	mv	s3,s1
    80005efc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005efe:	02000a13          	li	s4,32
    80005f02:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f06:	00391513          	slli	a0,s2,0x3
    80005f0a:	e3040593          	addi	a1,s0,-464
    80005f0e:	e3843783          	ld	a5,-456(s0)
    80005f12:	953e                	add	a0,a0,a5
    80005f14:	ffffd097          	auipc	ra,0xffffd
    80005f18:	092080e7          	jalr	146(ra) # 80002fa6 <fetchaddr>
    80005f1c:	02054a63          	bltz	a0,80005f50 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005f20:	e3043783          	ld	a5,-464(s0)
    80005f24:	c3b9                	beqz	a5,80005f6a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f26:	ffffb097          	auipc	ra,0xffffb
    80005f2a:	bce080e7          	jalr	-1074(ra) # 80000af4 <kalloc>
    80005f2e:	85aa                	mv	a1,a0
    80005f30:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f34:	cd11                	beqz	a0,80005f50 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f36:	6605                	lui	a2,0x1
    80005f38:	e3043503          	ld	a0,-464(s0)
    80005f3c:	ffffd097          	auipc	ra,0xffffd
    80005f40:	0bc080e7          	jalr	188(ra) # 80002ff8 <fetchstr>
    80005f44:	00054663          	bltz	a0,80005f50 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f48:	0905                	addi	s2,s2,1
    80005f4a:	09a1                	addi	s3,s3,8
    80005f4c:	fb491be3          	bne	s2,s4,80005f02 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f50:	10048913          	addi	s2,s1,256
    80005f54:	6088                	ld	a0,0(s1)
    80005f56:	c529                	beqz	a0,80005fa0 <sys_exec+0xf8>
    kfree(argv[i]);
    80005f58:	ffffb097          	auipc	ra,0xffffb
    80005f5c:	aa0080e7          	jalr	-1376(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f60:	04a1                	addi	s1,s1,8
    80005f62:	ff2499e3          	bne	s1,s2,80005f54 <sys_exec+0xac>
  return -1;
    80005f66:	597d                	li	s2,-1
    80005f68:	a82d                	j	80005fa2 <sys_exec+0xfa>
      argv[i] = 0;
    80005f6a:	0a8e                	slli	s5,s5,0x3
    80005f6c:	fc040793          	addi	a5,s0,-64
    80005f70:	9abe                	add	s5,s5,a5
    80005f72:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f76:	e4040593          	addi	a1,s0,-448
    80005f7a:	f4040513          	addi	a0,s0,-192
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	194080e7          	jalr	404(ra) # 80005112 <exec>
    80005f86:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f88:	10048993          	addi	s3,s1,256
    80005f8c:	6088                	ld	a0,0(s1)
    80005f8e:	c911                	beqz	a0,80005fa2 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	a68080e7          	jalr	-1432(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f98:	04a1                	addi	s1,s1,8
    80005f9a:	ff3499e3          	bne	s1,s3,80005f8c <sys_exec+0xe4>
    80005f9e:	a011                	j	80005fa2 <sys_exec+0xfa>
  return -1;
    80005fa0:	597d                	li	s2,-1
}
    80005fa2:	854a                	mv	a0,s2
    80005fa4:	60be                	ld	ra,456(sp)
    80005fa6:	641e                	ld	s0,448(sp)
    80005fa8:	74fa                	ld	s1,440(sp)
    80005faa:	795a                	ld	s2,432(sp)
    80005fac:	79ba                	ld	s3,424(sp)
    80005fae:	7a1a                	ld	s4,416(sp)
    80005fb0:	6afa                	ld	s5,408(sp)
    80005fb2:	6179                	addi	sp,sp,464
    80005fb4:	8082                	ret

0000000080005fb6 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005fb6:	7139                	addi	sp,sp,-64
    80005fb8:	fc06                	sd	ra,56(sp)
    80005fba:	f822                	sd	s0,48(sp)
    80005fbc:	f426                	sd	s1,40(sp)
    80005fbe:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005fc0:	ffffc097          	auipc	ra,0xffffc
    80005fc4:	9f0080e7          	jalr	-1552(ra) # 800019b0 <myproc>
    80005fc8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fca:	fd840593          	addi	a1,s0,-40
    80005fce:	4501                	li	a0,0
    80005fd0:	ffffd097          	auipc	ra,0xffffd
    80005fd4:	092080e7          	jalr	146(ra) # 80003062 <argaddr>
    return -1;
    80005fd8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fda:	0e054063          	bltz	a0,800060ba <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fde:	fc840593          	addi	a1,s0,-56
    80005fe2:	fd040513          	addi	a0,s0,-48
    80005fe6:	fffff097          	auipc	ra,0xfffff
    80005fea:	dfc080e7          	jalr	-516(ra) # 80004de2 <pipealloc>
    return -1;
    80005fee:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ff0:	0c054563          	bltz	a0,800060ba <sys_pipe+0x104>
  fd0 = -1;
    80005ff4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ff8:	fd043503          	ld	a0,-48(s0)
    80005ffc:	fffff097          	auipc	ra,0xfffff
    80006000:	508080e7          	jalr	1288(ra) # 80005504 <fdalloc>
    80006004:	fca42223          	sw	a0,-60(s0)
    80006008:	08054c63          	bltz	a0,800060a0 <sys_pipe+0xea>
    8000600c:	fc843503          	ld	a0,-56(s0)
    80006010:	fffff097          	auipc	ra,0xfffff
    80006014:	4f4080e7          	jalr	1268(ra) # 80005504 <fdalloc>
    80006018:	fca42023          	sw	a0,-64(s0)
    8000601c:	06054863          	bltz	a0,8000608c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006020:	4691                	li	a3,4
    80006022:	fc440613          	addi	a2,s0,-60
    80006026:	fd843583          	ld	a1,-40(s0)
    8000602a:	78a8                	ld	a0,112(s1)
    8000602c:	ffffb097          	auipc	ra,0xffffb
    80006030:	646080e7          	jalr	1606(ra) # 80001672 <copyout>
    80006034:	02054063          	bltz	a0,80006054 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006038:	4691                	li	a3,4
    8000603a:	fc040613          	addi	a2,s0,-64
    8000603e:	fd843583          	ld	a1,-40(s0)
    80006042:	0591                	addi	a1,a1,4
    80006044:	78a8                	ld	a0,112(s1)
    80006046:	ffffb097          	auipc	ra,0xffffb
    8000604a:	62c080e7          	jalr	1580(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000604e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006050:	06055563          	bgez	a0,800060ba <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006054:	fc442783          	lw	a5,-60(s0)
    80006058:	07f9                	addi	a5,a5,30
    8000605a:	078e                	slli	a5,a5,0x3
    8000605c:	97a6                	add	a5,a5,s1
    8000605e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006062:	fc042503          	lw	a0,-64(s0)
    80006066:	0579                	addi	a0,a0,30
    80006068:	050e                	slli	a0,a0,0x3
    8000606a:	9526                	add	a0,a0,s1
    8000606c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006070:	fd043503          	ld	a0,-48(s0)
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	a3e080e7          	jalr	-1474(ra) # 80004ab2 <fileclose>
    fileclose(wf);
    8000607c:	fc843503          	ld	a0,-56(s0)
    80006080:	fffff097          	auipc	ra,0xfffff
    80006084:	a32080e7          	jalr	-1486(ra) # 80004ab2 <fileclose>
    return -1;
    80006088:	57fd                	li	a5,-1
    8000608a:	a805                	j	800060ba <sys_pipe+0x104>
    if(fd0 >= 0)
    8000608c:	fc442783          	lw	a5,-60(s0)
    80006090:	0007c863          	bltz	a5,800060a0 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006094:	01e78513          	addi	a0,a5,30
    80006098:	050e                	slli	a0,a0,0x3
    8000609a:	9526                	add	a0,a0,s1
    8000609c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800060a0:	fd043503          	ld	a0,-48(s0)
    800060a4:	fffff097          	auipc	ra,0xfffff
    800060a8:	a0e080e7          	jalr	-1522(ra) # 80004ab2 <fileclose>
    fileclose(wf);
    800060ac:	fc843503          	ld	a0,-56(s0)
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	a02080e7          	jalr	-1534(ra) # 80004ab2 <fileclose>
    return -1;
    800060b8:	57fd                	li	a5,-1
}
    800060ba:	853e                	mv	a0,a5
    800060bc:	70e2                	ld	ra,56(sp)
    800060be:	7442                	ld	s0,48(sp)
    800060c0:	74a2                	ld	s1,40(sp)
    800060c2:	6121                	addi	sp,sp,64
    800060c4:	8082                	ret
	...

00000000800060d0 <kernelvec>:
    800060d0:	7111                	addi	sp,sp,-256
    800060d2:	e006                	sd	ra,0(sp)
    800060d4:	e40a                	sd	sp,8(sp)
    800060d6:	e80e                	sd	gp,16(sp)
    800060d8:	ec12                	sd	tp,24(sp)
    800060da:	f016                	sd	t0,32(sp)
    800060dc:	f41a                	sd	t1,40(sp)
    800060de:	f81e                	sd	t2,48(sp)
    800060e0:	fc22                	sd	s0,56(sp)
    800060e2:	e0a6                	sd	s1,64(sp)
    800060e4:	e4aa                	sd	a0,72(sp)
    800060e6:	e8ae                	sd	a1,80(sp)
    800060e8:	ecb2                	sd	a2,88(sp)
    800060ea:	f0b6                	sd	a3,96(sp)
    800060ec:	f4ba                	sd	a4,104(sp)
    800060ee:	f8be                	sd	a5,112(sp)
    800060f0:	fcc2                	sd	a6,120(sp)
    800060f2:	e146                	sd	a7,128(sp)
    800060f4:	e54a                	sd	s2,136(sp)
    800060f6:	e94e                	sd	s3,144(sp)
    800060f8:	ed52                	sd	s4,152(sp)
    800060fa:	f156                	sd	s5,160(sp)
    800060fc:	f55a                	sd	s6,168(sp)
    800060fe:	f95e                	sd	s7,176(sp)
    80006100:	fd62                	sd	s8,184(sp)
    80006102:	e1e6                	sd	s9,192(sp)
    80006104:	e5ea                	sd	s10,200(sp)
    80006106:	e9ee                	sd	s11,208(sp)
    80006108:	edf2                	sd	t3,216(sp)
    8000610a:	f1f6                	sd	t4,224(sp)
    8000610c:	f5fa                	sd	t5,232(sp)
    8000610e:	f9fe                	sd	t6,240(sp)
    80006110:	d63fc0ef          	jal	ra,80002e72 <kerneltrap>
    80006114:	6082                	ld	ra,0(sp)
    80006116:	6122                	ld	sp,8(sp)
    80006118:	61c2                	ld	gp,16(sp)
    8000611a:	7282                	ld	t0,32(sp)
    8000611c:	7322                	ld	t1,40(sp)
    8000611e:	73c2                	ld	t2,48(sp)
    80006120:	7462                	ld	s0,56(sp)
    80006122:	6486                	ld	s1,64(sp)
    80006124:	6526                	ld	a0,72(sp)
    80006126:	65c6                	ld	a1,80(sp)
    80006128:	6666                	ld	a2,88(sp)
    8000612a:	7686                	ld	a3,96(sp)
    8000612c:	7726                	ld	a4,104(sp)
    8000612e:	77c6                	ld	a5,112(sp)
    80006130:	7866                	ld	a6,120(sp)
    80006132:	688a                	ld	a7,128(sp)
    80006134:	692a                	ld	s2,136(sp)
    80006136:	69ca                	ld	s3,144(sp)
    80006138:	6a6a                	ld	s4,152(sp)
    8000613a:	7a8a                	ld	s5,160(sp)
    8000613c:	7b2a                	ld	s6,168(sp)
    8000613e:	7bca                	ld	s7,176(sp)
    80006140:	7c6a                	ld	s8,184(sp)
    80006142:	6c8e                	ld	s9,192(sp)
    80006144:	6d2e                	ld	s10,200(sp)
    80006146:	6dce                	ld	s11,208(sp)
    80006148:	6e6e                	ld	t3,216(sp)
    8000614a:	7e8e                	ld	t4,224(sp)
    8000614c:	7f2e                	ld	t5,232(sp)
    8000614e:	7fce                	ld	t6,240(sp)
    80006150:	6111                	addi	sp,sp,256
    80006152:	10200073          	sret
    80006156:	00000013          	nop
    8000615a:	00000013          	nop
    8000615e:	0001                	nop

0000000080006160 <timervec>:
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	e10c                	sd	a1,0(a0)
    80006166:	e510                	sd	a2,8(a0)
    80006168:	e914                	sd	a3,16(a0)
    8000616a:	6d0c                	ld	a1,24(a0)
    8000616c:	7110                	ld	a2,32(a0)
    8000616e:	6194                	ld	a3,0(a1)
    80006170:	96b2                	add	a3,a3,a2
    80006172:	e194                	sd	a3,0(a1)
    80006174:	4589                	li	a1,2
    80006176:	14459073          	csrw	sip,a1
    8000617a:	6914                	ld	a3,16(a0)
    8000617c:	6510                	ld	a2,8(a0)
    8000617e:	610c                	ld	a1,0(a0)
    80006180:	34051573          	csrrw	a0,mscratch,a0
    80006184:	30200073          	mret
	...

000000008000618a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000618a:	1141                	addi	sp,sp,-16
    8000618c:	e422                	sd	s0,8(sp)
    8000618e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006190:	0c0007b7          	lui	a5,0xc000
    80006194:	4705                	li	a4,1
    80006196:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006198:	c3d8                	sw	a4,4(a5)
}
    8000619a:	6422                	ld	s0,8(sp)
    8000619c:	0141                	addi	sp,sp,16
    8000619e:	8082                	ret

00000000800061a0 <plicinithart>:

void
plicinithart(void)
{
    800061a0:	1141                	addi	sp,sp,-16
    800061a2:	e406                	sd	ra,8(sp)
    800061a4:	e022                	sd	s0,0(sp)
    800061a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061a8:	ffffb097          	auipc	ra,0xffffb
    800061ac:	7dc080e7          	jalr	2012(ra) # 80001984 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061b0:	0085171b          	slliw	a4,a0,0x8
    800061b4:	0c0027b7          	lui	a5,0xc002
    800061b8:	97ba                	add	a5,a5,a4
    800061ba:	40200713          	li	a4,1026
    800061be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061c2:	00d5151b          	slliw	a0,a0,0xd
    800061c6:	0c2017b7          	lui	a5,0xc201
    800061ca:	953e                	add	a0,a0,a5
    800061cc:	00052023          	sw	zero,0(a0)
}
    800061d0:	60a2                	ld	ra,8(sp)
    800061d2:	6402                	ld	s0,0(sp)
    800061d4:	0141                	addi	sp,sp,16
    800061d6:	8082                	ret

00000000800061d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061d8:	1141                	addi	sp,sp,-16
    800061da:	e406                	sd	ra,8(sp)
    800061dc:	e022                	sd	s0,0(sp)
    800061de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e0:	ffffb097          	auipc	ra,0xffffb
    800061e4:	7a4080e7          	jalr	1956(ra) # 80001984 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061e8:	00d5179b          	slliw	a5,a0,0xd
    800061ec:	0c201537          	lui	a0,0xc201
    800061f0:	953e                	add	a0,a0,a5
  return irq;
}
    800061f2:	4148                	lw	a0,4(a0)
    800061f4:	60a2                	ld	ra,8(sp)
    800061f6:	6402                	ld	s0,0(sp)
    800061f8:	0141                	addi	sp,sp,16
    800061fa:	8082                	ret

00000000800061fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061fc:	1101                	addi	sp,sp,-32
    800061fe:	ec06                	sd	ra,24(sp)
    80006200:	e822                	sd	s0,16(sp)
    80006202:	e426                	sd	s1,8(sp)
    80006204:	1000                	addi	s0,sp,32
    80006206:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	77c080e7          	jalr	1916(ra) # 80001984 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006210:	00d5151b          	slliw	a0,a0,0xd
    80006214:	0c2017b7          	lui	a5,0xc201
    80006218:	97aa                	add	a5,a5,a0
    8000621a:	c3c4                	sw	s1,4(a5)
}
    8000621c:	60e2                	ld	ra,24(sp)
    8000621e:	6442                	ld	s0,16(sp)
    80006220:	64a2                	ld	s1,8(sp)
    80006222:	6105                	addi	sp,sp,32
    80006224:	8082                	ret

0000000080006226 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006226:	1141                	addi	sp,sp,-16
    80006228:	e406                	sd	ra,8(sp)
    8000622a:	e022                	sd	s0,0(sp)
    8000622c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000622e:	479d                	li	a5,7
    80006230:	06a7c963          	blt	a5,a0,800062a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006234:	0001d797          	auipc	a5,0x1d
    80006238:	dcc78793          	addi	a5,a5,-564 # 80023000 <disk>
    8000623c:	00a78733          	add	a4,a5,a0
    80006240:	6789                	lui	a5,0x2
    80006242:	97ba                	add	a5,a5,a4
    80006244:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006248:	e7ad                	bnez	a5,800062b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000624a:	00451793          	slli	a5,a0,0x4
    8000624e:	0001f717          	auipc	a4,0x1f
    80006252:	db270713          	addi	a4,a4,-590 # 80025000 <disk+0x2000>
    80006256:	6314                	ld	a3,0(a4)
    80006258:	96be                	add	a3,a3,a5
    8000625a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000625e:	6314                	ld	a3,0(a4)
    80006260:	96be                	add	a3,a3,a5
    80006262:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006266:	6314                	ld	a3,0(a4)
    80006268:	96be                	add	a3,a3,a5
    8000626a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000626e:	6318                	ld	a4,0(a4)
    80006270:	97ba                	add	a5,a5,a4
    80006272:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006276:	0001d797          	auipc	a5,0x1d
    8000627a:	d8a78793          	addi	a5,a5,-630 # 80023000 <disk>
    8000627e:	97aa                	add	a5,a5,a0
    80006280:	6509                	lui	a0,0x2
    80006282:	953e                	add	a0,a0,a5
    80006284:	4785                	li	a5,1
    80006286:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000628a:	0001f517          	auipc	a0,0x1f
    8000628e:	d8e50513          	addi	a0,a0,-626 # 80025018 <disk+0x2018>
    80006292:	ffffc097          	auipc	ra,0xffffc
    80006296:	f10080e7          	jalr	-240(ra) # 800021a2 <wakeup>
}
    8000629a:	60a2                	ld	ra,8(sp)
    8000629c:	6402                	ld	s0,0(sp)
    8000629e:	0141                	addi	sp,sp,16
    800062a0:	8082                	ret
    panic("free_desc 1");
    800062a2:	00002517          	auipc	a0,0x2
    800062a6:	5ee50513          	addi	a0,a0,1518 # 80008890 <syscalls+0x338>
    800062aa:	ffffa097          	auipc	ra,0xffffa
    800062ae:	294080e7          	jalr	660(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062b2:	00002517          	auipc	a0,0x2
    800062b6:	5ee50513          	addi	a0,a0,1518 # 800088a0 <syscalls+0x348>
    800062ba:	ffffa097          	auipc	ra,0xffffa
    800062be:	284080e7          	jalr	644(ra) # 8000053e <panic>

00000000800062c2 <virtio_disk_init>:
{
    800062c2:	1101                	addi	sp,sp,-32
    800062c4:	ec06                	sd	ra,24(sp)
    800062c6:	e822                	sd	s0,16(sp)
    800062c8:	e426                	sd	s1,8(sp)
    800062ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062cc:	00002597          	auipc	a1,0x2
    800062d0:	5e458593          	addi	a1,a1,1508 # 800088b0 <syscalls+0x358>
    800062d4:	0001f517          	auipc	a0,0x1f
    800062d8:	e5450513          	addi	a0,a0,-428 # 80025128 <disk+0x2128>
    800062dc:	ffffb097          	auipc	ra,0xffffb
    800062e0:	878080e7          	jalr	-1928(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e4:	100017b7          	lui	a5,0x10001
    800062e8:	4398                	lw	a4,0(a5)
    800062ea:	2701                	sext.w	a4,a4
    800062ec:	747277b7          	lui	a5,0x74727
    800062f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062f4:	0ef71163          	bne	a4,a5,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062f8:	100017b7          	lui	a5,0x10001
    800062fc:	43dc                	lw	a5,4(a5)
    800062fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006300:	4705                	li	a4,1
    80006302:	0ce79a63          	bne	a5,a4,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006306:	100017b7          	lui	a5,0x10001
    8000630a:	479c                	lw	a5,8(a5)
    8000630c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000630e:	4709                	li	a4,2
    80006310:	0ce79363          	bne	a5,a4,800063d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006314:	100017b7          	lui	a5,0x10001
    80006318:	47d8                	lw	a4,12(a5)
    8000631a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000631c:	554d47b7          	lui	a5,0x554d4
    80006320:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006324:	0af71963          	bne	a4,a5,800063d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006328:	100017b7          	lui	a5,0x10001
    8000632c:	4705                	li	a4,1
    8000632e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006330:	470d                	li	a4,3
    80006332:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006334:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006336:	c7ffe737          	lui	a4,0xc7ffe
    8000633a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000633e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006340:	2701                	sext.w	a4,a4
    80006342:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006344:	472d                	li	a4,11
    80006346:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006348:	473d                	li	a4,15
    8000634a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000634c:	6705                	lui	a4,0x1
    8000634e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006350:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006354:	5bdc                	lw	a5,52(a5)
    80006356:	2781                	sext.w	a5,a5
  if(max == 0)
    80006358:	c7d9                	beqz	a5,800063e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000635a:	471d                	li	a4,7
    8000635c:	08f77d63          	bgeu	a4,a5,800063f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006360:	100014b7          	lui	s1,0x10001
    80006364:	47a1                	li	a5,8
    80006366:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006368:	6609                	lui	a2,0x2
    8000636a:	4581                	li	a1,0
    8000636c:	0001d517          	auipc	a0,0x1d
    80006370:	c9450513          	addi	a0,a0,-876 # 80023000 <disk>
    80006374:	ffffb097          	auipc	ra,0xffffb
    80006378:	96c080e7          	jalr	-1684(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000637c:	0001d717          	auipc	a4,0x1d
    80006380:	c8470713          	addi	a4,a4,-892 # 80023000 <disk>
    80006384:	00c75793          	srli	a5,a4,0xc
    80006388:	2781                	sext.w	a5,a5
    8000638a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000638c:	0001f797          	auipc	a5,0x1f
    80006390:	c7478793          	addi	a5,a5,-908 # 80025000 <disk+0x2000>
    80006394:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006396:	0001d717          	auipc	a4,0x1d
    8000639a:	cea70713          	addi	a4,a4,-790 # 80023080 <disk+0x80>
    8000639e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063a0:	0001e717          	auipc	a4,0x1e
    800063a4:	c6070713          	addi	a4,a4,-928 # 80024000 <disk+0x1000>
    800063a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063aa:	4705                	li	a4,1
    800063ac:	00e78c23          	sb	a4,24(a5)
    800063b0:	00e78ca3          	sb	a4,25(a5)
    800063b4:	00e78d23          	sb	a4,26(a5)
    800063b8:	00e78da3          	sb	a4,27(a5)
    800063bc:	00e78e23          	sb	a4,28(a5)
    800063c0:	00e78ea3          	sb	a4,29(a5)
    800063c4:	00e78f23          	sb	a4,30(a5)
    800063c8:	00e78fa3          	sb	a4,31(a5)
}
    800063cc:	60e2                	ld	ra,24(sp)
    800063ce:	6442                	ld	s0,16(sp)
    800063d0:	64a2                	ld	s1,8(sp)
    800063d2:	6105                	addi	sp,sp,32
    800063d4:	8082                	ret
    panic("could not find virtio disk");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	4ea50513          	addi	a0,a0,1258 # 800088c0 <syscalls+0x368>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	160080e7          	jalr	352(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    800063e6:	00002517          	auipc	a0,0x2
    800063ea:	4fa50513          	addi	a0,a0,1274 # 800088e0 <syscalls+0x388>
    800063ee:	ffffa097          	auipc	ra,0xffffa
    800063f2:	150080e7          	jalr	336(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	50a50513          	addi	a0,a0,1290 # 80008900 <syscalls+0x3a8>
    800063fe:	ffffa097          	auipc	ra,0xffffa
    80006402:	140080e7          	jalr	320(ra) # 8000053e <panic>

0000000080006406 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006406:	7159                	addi	sp,sp,-112
    80006408:	f486                	sd	ra,104(sp)
    8000640a:	f0a2                	sd	s0,96(sp)
    8000640c:	eca6                	sd	s1,88(sp)
    8000640e:	e8ca                	sd	s2,80(sp)
    80006410:	e4ce                	sd	s3,72(sp)
    80006412:	e0d2                	sd	s4,64(sp)
    80006414:	fc56                	sd	s5,56(sp)
    80006416:	f85a                	sd	s6,48(sp)
    80006418:	f45e                	sd	s7,40(sp)
    8000641a:	f062                	sd	s8,32(sp)
    8000641c:	ec66                	sd	s9,24(sp)
    8000641e:	e86a                	sd	s10,16(sp)
    80006420:	1880                	addi	s0,sp,112
    80006422:	892a                	mv	s2,a0
    80006424:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006426:	00c52c83          	lw	s9,12(a0)
    8000642a:	001c9c9b          	slliw	s9,s9,0x1
    8000642e:	1c82                	slli	s9,s9,0x20
    80006430:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006434:	0001f517          	auipc	a0,0x1f
    80006438:	cf450513          	addi	a0,a0,-780 # 80025128 <disk+0x2128>
    8000643c:	ffffa097          	auipc	ra,0xffffa
    80006440:	7a8080e7          	jalr	1960(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80006444:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006446:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006448:	0001db97          	auipc	s7,0x1d
    8000644c:	bb8b8b93          	addi	s7,s7,-1096 # 80023000 <disk>
    80006450:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006452:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006454:	8a4e                	mv	s4,s3
    80006456:	a051                	j	800064da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006458:	00fb86b3          	add	a3,s7,a5
    8000645c:	96da                	add	a3,a3,s6
    8000645e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006462:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006464:	0207c563          	bltz	a5,8000648e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006468:	2485                	addiw	s1,s1,1
    8000646a:	0711                	addi	a4,a4,4
    8000646c:	25548063          	beq	s1,s5,800066ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006470:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006472:	0001f697          	auipc	a3,0x1f
    80006476:	ba668693          	addi	a3,a3,-1114 # 80025018 <disk+0x2018>
    8000647a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000647c:	0006c583          	lbu	a1,0(a3)
    80006480:	fde1                	bnez	a1,80006458 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006482:	2785                	addiw	a5,a5,1
    80006484:	0685                	addi	a3,a3,1
    80006486:	ff879be3          	bne	a5,s8,8000647c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000648a:	57fd                	li	a5,-1
    8000648c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000648e:	02905a63          	blez	s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006492:	f9042503          	lw	a0,-112(s0)
    80006496:	00000097          	auipc	ra,0x0
    8000649a:	d90080e7          	jalr	-624(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    8000649e:	4785                	li	a5,1
    800064a0:	0297d163          	bge	a5,s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064a4:	f9442503          	lw	a0,-108(s0)
    800064a8:	00000097          	auipc	ra,0x0
    800064ac:	d7e080e7          	jalr	-642(ra) # 80006226 <free_desc>
      for(int j = 0; j < i; j++)
    800064b0:	4789                	li	a5,2
    800064b2:	0097d863          	bge	a5,s1,800064c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064b6:	f9842503          	lw	a0,-104(s0)
    800064ba:	00000097          	auipc	ra,0x0
    800064be:	d6c080e7          	jalr	-660(ra) # 80006226 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064c2:	0001f597          	auipc	a1,0x1f
    800064c6:	c6658593          	addi	a1,a1,-922 # 80025128 <disk+0x2128>
    800064ca:	0001f517          	auipc	a0,0x1f
    800064ce:	b4e50513          	addi	a0,a0,-1202 # 80025018 <disk+0x2018>
    800064d2:	ffffc097          	auipc	ra,0xffffc
    800064d6:	b44080e7          	jalr	-1212(ra) # 80002016 <sleep>
  for(int i = 0; i < 3; i++){
    800064da:	f9040713          	addi	a4,s0,-112
    800064de:	84ce                	mv	s1,s3
    800064e0:	bf41                	j	80006470 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064e2:	20058713          	addi	a4,a1,512
    800064e6:	00471693          	slli	a3,a4,0x4
    800064ea:	0001d717          	auipc	a4,0x1d
    800064ee:	b1670713          	addi	a4,a4,-1258 # 80023000 <disk>
    800064f2:	9736                	add	a4,a4,a3
    800064f4:	4685                	li	a3,1
    800064f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064fa:	20058713          	addi	a4,a1,512
    800064fe:	00471693          	slli	a3,a4,0x4
    80006502:	0001d717          	auipc	a4,0x1d
    80006506:	afe70713          	addi	a4,a4,-1282 # 80023000 <disk>
    8000650a:	9736                	add	a4,a4,a3
    8000650c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006510:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006514:	7679                	lui	a2,0xffffe
    80006516:	963e                	add	a2,a2,a5
    80006518:	0001f697          	auipc	a3,0x1f
    8000651c:	ae868693          	addi	a3,a3,-1304 # 80025000 <disk+0x2000>
    80006520:	6298                	ld	a4,0(a3)
    80006522:	9732                	add	a4,a4,a2
    80006524:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006526:	6298                	ld	a4,0(a3)
    80006528:	9732                	add	a4,a4,a2
    8000652a:	4541                	li	a0,16
    8000652c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000652e:	6298                	ld	a4,0(a3)
    80006530:	9732                	add	a4,a4,a2
    80006532:	4505                	li	a0,1
    80006534:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006538:	f9442703          	lw	a4,-108(s0)
    8000653c:	6288                	ld	a0,0(a3)
    8000653e:	962a                	add	a2,a2,a0
    80006540:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006544:	0712                	slli	a4,a4,0x4
    80006546:	6290                	ld	a2,0(a3)
    80006548:	963a                	add	a2,a2,a4
    8000654a:	05890513          	addi	a0,s2,88
    8000654e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006550:	6294                	ld	a3,0(a3)
    80006552:	96ba                	add	a3,a3,a4
    80006554:	40000613          	li	a2,1024
    80006558:	c690                	sw	a2,8(a3)
  if(write)
    8000655a:	140d0063          	beqz	s10,8000669a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000655e:	0001f697          	auipc	a3,0x1f
    80006562:	aa26b683          	ld	a3,-1374(a3) # 80025000 <disk+0x2000>
    80006566:	96ba                	add	a3,a3,a4
    80006568:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000656c:	0001d817          	auipc	a6,0x1d
    80006570:	a9480813          	addi	a6,a6,-1388 # 80023000 <disk>
    80006574:	0001f517          	auipc	a0,0x1f
    80006578:	a8c50513          	addi	a0,a0,-1396 # 80025000 <disk+0x2000>
    8000657c:	6114                	ld	a3,0(a0)
    8000657e:	96ba                	add	a3,a3,a4
    80006580:	00c6d603          	lhu	a2,12(a3)
    80006584:	00166613          	ori	a2,a2,1
    80006588:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000658c:	f9842683          	lw	a3,-104(s0)
    80006590:	6110                	ld	a2,0(a0)
    80006592:	9732                	add	a4,a4,a2
    80006594:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006598:	20058613          	addi	a2,a1,512
    8000659c:	0612                	slli	a2,a2,0x4
    8000659e:	9642                	add	a2,a2,a6
    800065a0:	577d                	li	a4,-1
    800065a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065a6:	00469713          	slli	a4,a3,0x4
    800065aa:	6114                	ld	a3,0(a0)
    800065ac:	96ba                	add	a3,a3,a4
    800065ae:	03078793          	addi	a5,a5,48
    800065b2:	97c2                	add	a5,a5,a6
    800065b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800065b6:	611c                	ld	a5,0(a0)
    800065b8:	97ba                	add	a5,a5,a4
    800065ba:	4685                	li	a3,1
    800065bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065be:	611c                	ld	a5,0(a0)
    800065c0:	97ba                	add	a5,a5,a4
    800065c2:	4809                	li	a6,2
    800065c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065c8:	611c                	ld	a5,0(a0)
    800065ca:	973e                	add	a4,a4,a5
    800065cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065d8:	6518                	ld	a4,8(a0)
    800065da:	00275783          	lhu	a5,2(a4)
    800065de:	8b9d                	andi	a5,a5,7
    800065e0:	0786                	slli	a5,a5,0x1
    800065e2:	97ba                	add	a5,a5,a4
    800065e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800065e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065ec:	6518                	ld	a4,8(a0)
    800065ee:	00275783          	lhu	a5,2(a4)
    800065f2:	2785                	addiw	a5,a5,1
    800065f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065fc:	100017b7          	lui	a5,0x10001
    80006600:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006604:	00492703          	lw	a4,4(s2)
    80006608:	4785                	li	a5,1
    8000660a:	02f71163          	bne	a4,a5,8000662c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000660e:	0001f997          	auipc	s3,0x1f
    80006612:	b1a98993          	addi	s3,s3,-1254 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006616:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006618:	85ce                	mv	a1,s3
    8000661a:	854a                	mv	a0,s2
    8000661c:	ffffc097          	auipc	ra,0xffffc
    80006620:	9fa080e7          	jalr	-1542(ra) # 80002016 <sleep>
  while(b->disk == 1) {
    80006624:	00492783          	lw	a5,4(s2)
    80006628:	fe9788e3          	beq	a5,s1,80006618 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000662c:	f9042903          	lw	s2,-112(s0)
    80006630:	20090793          	addi	a5,s2,512
    80006634:	00479713          	slli	a4,a5,0x4
    80006638:	0001d797          	auipc	a5,0x1d
    8000663c:	9c878793          	addi	a5,a5,-1592 # 80023000 <disk>
    80006640:	97ba                	add	a5,a5,a4
    80006642:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006646:	0001f997          	auipc	s3,0x1f
    8000664a:	9ba98993          	addi	s3,s3,-1606 # 80025000 <disk+0x2000>
    8000664e:	00491713          	slli	a4,s2,0x4
    80006652:	0009b783          	ld	a5,0(s3)
    80006656:	97ba                	add	a5,a5,a4
    80006658:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000665c:	854a                	mv	a0,s2
    8000665e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006662:	00000097          	auipc	ra,0x0
    80006666:	bc4080e7          	jalr	-1084(ra) # 80006226 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000666a:	8885                	andi	s1,s1,1
    8000666c:	f0ed                	bnez	s1,8000664e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000666e:	0001f517          	auipc	a0,0x1f
    80006672:	aba50513          	addi	a0,a0,-1350 # 80025128 <disk+0x2128>
    80006676:	ffffa097          	auipc	ra,0xffffa
    8000667a:	622080e7          	jalr	1570(ra) # 80000c98 <release>
}
    8000667e:	70a6                	ld	ra,104(sp)
    80006680:	7406                	ld	s0,96(sp)
    80006682:	64e6                	ld	s1,88(sp)
    80006684:	6946                	ld	s2,80(sp)
    80006686:	69a6                	ld	s3,72(sp)
    80006688:	6a06                	ld	s4,64(sp)
    8000668a:	7ae2                	ld	s5,56(sp)
    8000668c:	7b42                	ld	s6,48(sp)
    8000668e:	7ba2                	ld	s7,40(sp)
    80006690:	7c02                	ld	s8,32(sp)
    80006692:	6ce2                	ld	s9,24(sp)
    80006694:	6d42                	ld	s10,16(sp)
    80006696:	6165                	addi	sp,sp,112
    80006698:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000669a:	0001f697          	auipc	a3,0x1f
    8000669e:	9666b683          	ld	a3,-1690(a3) # 80025000 <disk+0x2000>
    800066a2:	96ba                	add	a3,a3,a4
    800066a4:	4609                	li	a2,2
    800066a6:	00c69623          	sh	a2,12(a3)
    800066aa:	b5c9                	j	8000656c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066ac:	f9042583          	lw	a1,-112(s0)
    800066b0:	20058793          	addi	a5,a1,512
    800066b4:	0792                	slli	a5,a5,0x4
    800066b6:	0001d517          	auipc	a0,0x1d
    800066ba:	9f250513          	addi	a0,a0,-1550 # 800230a8 <disk+0xa8>
    800066be:	953e                	add	a0,a0,a5
  if(write)
    800066c0:	e20d11e3          	bnez	s10,800064e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066c4:	20058713          	addi	a4,a1,512
    800066c8:	00471693          	slli	a3,a4,0x4
    800066cc:	0001d717          	auipc	a4,0x1d
    800066d0:	93470713          	addi	a4,a4,-1740 # 80023000 <disk>
    800066d4:	9736                	add	a4,a4,a3
    800066d6:	0a072423          	sw	zero,168(a4)
    800066da:	b505                	j	800064fa <virtio_disk_rw+0xf4>

00000000800066dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066dc:	1101                	addi	sp,sp,-32
    800066de:	ec06                	sd	ra,24(sp)
    800066e0:	e822                	sd	s0,16(sp)
    800066e2:	e426                	sd	s1,8(sp)
    800066e4:	e04a                	sd	s2,0(sp)
    800066e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066e8:	0001f517          	auipc	a0,0x1f
    800066ec:	a4050513          	addi	a0,a0,-1472 # 80025128 <disk+0x2128>
    800066f0:	ffffa097          	auipc	ra,0xffffa
    800066f4:	4f4080e7          	jalr	1268(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066f8:	10001737          	lui	a4,0x10001
    800066fc:	533c                	lw	a5,96(a4)
    800066fe:	8b8d                	andi	a5,a5,3
    80006700:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006702:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006706:	0001f797          	auipc	a5,0x1f
    8000670a:	8fa78793          	addi	a5,a5,-1798 # 80025000 <disk+0x2000>
    8000670e:	6b94                	ld	a3,16(a5)
    80006710:	0207d703          	lhu	a4,32(a5)
    80006714:	0026d783          	lhu	a5,2(a3)
    80006718:	06f70163          	beq	a4,a5,8000677a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000671c:	0001d917          	auipc	s2,0x1d
    80006720:	8e490913          	addi	s2,s2,-1820 # 80023000 <disk>
    80006724:	0001f497          	auipc	s1,0x1f
    80006728:	8dc48493          	addi	s1,s1,-1828 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000672c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006730:	6898                	ld	a4,16(s1)
    80006732:	0204d783          	lhu	a5,32(s1)
    80006736:	8b9d                	andi	a5,a5,7
    80006738:	078e                	slli	a5,a5,0x3
    8000673a:	97ba                	add	a5,a5,a4
    8000673c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000673e:	20078713          	addi	a4,a5,512
    80006742:	0712                	slli	a4,a4,0x4
    80006744:	974a                	add	a4,a4,s2
    80006746:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000674a:	e731                	bnez	a4,80006796 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000674c:	20078793          	addi	a5,a5,512
    80006750:	0792                	slli	a5,a5,0x4
    80006752:	97ca                	add	a5,a5,s2
    80006754:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006756:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000675a:	ffffc097          	auipc	ra,0xffffc
    8000675e:	a48080e7          	jalr	-1464(ra) # 800021a2 <wakeup>

    disk.used_idx += 1;
    80006762:	0204d783          	lhu	a5,32(s1)
    80006766:	2785                	addiw	a5,a5,1
    80006768:	17c2                	slli	a5,a5,0x30
    8000676a:	93c1                	srli	a5,a5,0x30
    8000676c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006770:	6898                	ld	a4,16(s1)
    80006772:	00275703          	lhu	a4,2(a4)
    80006776:	faf71be3          	bne	a4,a5,8000672c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000677a:	0001f517          	auipc	a0,0x1f
    8000677e:	9ae50513          	addi	a0,a0,-1618 # 80025128 <disk+0x2128>
    80006782:	ffffa097          	auipc	ra,0xffffa
    80006786:	516080e7          	jalr	1302(ra) # 80000c98 <release>
}
    8000678a:	60e2                	ld	ra,24(sp)
    8000678c:	6442                	ld	s0,16(sp)
    8000678e:	64a2                	ld	s1,8(sp)
    80006790:	6902                	ld	s2,0(sp)
    80006792:	6105                	addi	sp,sp,32
    80006794:	8082                	ret
      panic("virtio_disk_intr status");
    80006796:	00002517          	auipc	a0,0x2
    8000679a:	18a50513          	addi	a0,a0,394 # 80008920 <syscalls+0x3c8>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	da0080e7          	jalr	-608(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
