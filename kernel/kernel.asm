
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	85013103          	ld	sp,-1968(sp) # 80008850 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000056:	85e70713          	addi	a4,a4,-1954 # 800088b0 <timer_scratch>
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
    80000068:	d3c78793          	addi	a5,a5,-708 # 80005da0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdcadf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
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
    80000130:	556080e7          	jalr	1366(ra) # 80002682 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
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
    80000190:	86450513          	addi	a0,a0,-1948 # 800109f0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	85448493          	addi	s1,s1,-1964 # 800109f0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	8e290913          	addi	s2,s2,-1822 # 80010a88 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

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
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	950080e7          	jalr	-1712(ra) # 80001b14 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	300080e7          	jalr	768(ra) # 800024cc <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	04a080e7          	jalr	74(ra) # 80002224 <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	416080e7          	jalr	1046(ra) # 8000262c <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00010517          	auipc	a0,0x10
    8000022e:	7c650513          	addi	a0,a0,1990 # 800109f0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00010517          	auipc	a0,0x10
    80000244:	7b050513          	addi	a0,a0,1968 # 800109f0 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	80f72823          	sw	a5,-2032(a4) # 80010a88 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	71e50513          	addi	a0,a0,1822 # 800109f0 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	3e0080e7          	jalr	992(ra) # 800026d8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	6f050513          	addi	a0,a0,1776 # 800109f0 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	6cc70713          	addi	a4,a4,1740 # 800109f0 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	6a278793          	addi	a5,a5,1698 # 800109f0 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	70c7a783          	lw	a5,1804(a5) # 80010a88 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	66070713          	addi	a4,a4,1632 # 800109f0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	65048493          	addi	s1,s1,1616 # 800109f0 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	61470713          	addi	a4,a4,1556 # 800109f0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	68f72f23          	sw	a5,1694(a4) # 80010a90 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	5d878793          	addi	a5,a5,1496 # 800109f0 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	64c7a823          	sw	a2,1616(a5) # 80010a8c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	64450513          	addi	a0,a0,1604 # 80010a88 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	e3c080e7          	jalr	-452(ra) # 80002288 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	58a50513          	addi	a0,a0,1418 # 800109f0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00020797          	auipc	a5,0x20
    80000482:	70a78793          	addi	a5,a5,1802 # 80020b88 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5607a023          	sw	zero,1376(a5) # 80010ab0 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	2ef72623          	sw	a5,748(a4) # 80008870 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	4f0dad83          	lw	s11,1264(s11) # 80010ab0 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	49a50513          	addi	a0,a0,1178 # 80010a98 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	33650513          	addi	a0,a0,822 # 80010a98 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	31a48493          	addi	s1,s1,794 # 80010a98 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	2da50513          	addi	a0,a0,730 # 80010ab8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0667a783          	lw	a5,102(a5) # 80008870 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	03273703          	ld	a4,50(a4) # 80008878 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0327b783          	ld	a5,50(a5) # 80008880 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	248a0a13          	addi	s4,s4,584 # 80010ab8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	00048493          	mv	s1,s1
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	00098993          	mv	s3,s3
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	9e2080e7          	jalr	-1566(ra) # 80002288 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3) # 80008880 <uart_tx_w>
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	1d650513          	addi	a0,a0,470 # 80010ab8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	f7e7a783          	lw	a5,-130(a5) # 80008870 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	f847b783          	ld	a5,-124(a5) # 80008880 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	f7473703          	ld	a4,-140(a4) # 80008878 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	1a8a0a13          	addi	s4,s4,424 # 80010ab8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	f6048493          	addi	s1,s1,-160 # 80008878 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	f6090913          	addi	s2,s2,-160 # 80008880 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	8f4080e7          	jalr	-1804(ra) # 80002224 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	17248493          	addi	s1,s1,370 # 80010ab8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f2f73323          	sd	a5,-218(a4) # 80008880 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	0e848493          	addi	s1,s1,232 # 80010ab8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	30e78793          	addi	a5,a5,782 # 80021d20 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	0be90913          	addi	s2,s2,190 # 80010af0 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	02250513          	addi	a0,a0,34 # 80010af0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	23e50513          	addi	a0,a0,574 # 80021d20 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	fec48493          	addi	s1,s1,-20 # 80010af0 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	fd450513          	addi	a0,a0,-44 # 80010af0 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	fa850513          	addi	a0,a0,-88 # 80010af0 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	f74080e7          	jalr	-140(ra) # 80001af8 <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	f42080e7          	jalr	-190(ra) # 80001af8 <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	f36080e7          	jalr	-202(ra) # 80001af8 <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	f1e080e7          	jalr	-226(ra) # 80001af8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	ede080e7          	jalr	-290(ra) # 80001af8 <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	eb2080e7          	jalr	-334(ra) # 80001af8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	c4c080e7          	jalr	-948(ra) # 80001ae8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	9e470713          	addi	a4,a4,-1564 # 80008888 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	c30080e7          	jalr	-976(ra) # 80001ae8 <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	190080e7          	jalr	400(ra) # 80001062 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	93e080e7          	jalr	-1730(ra) # 80002818 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	efe080e7          	jalr	-258(ra) # 80005de0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	188080e7          	jalr	392(ra) # 80002072 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	390080e7          	jalr	912(ra) # 800012ca <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	120080e7          	jalr	288(ra) # 80001062 <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	aea080e7          	jalr	-1302(ra) # 80001a34 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	89e080e7          	jalr	-1890(ra) # 800027f0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	8be080e7          	jalr	-1858(ra) # 80002818 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	e68080e7          	jalr	-408(ra) # 80005dca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	e76080e7          	jalr	-394(ra) # 80005de0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	016080e7          	jalr	22(ra) # 80002f88 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	6ba080e7          	jalr	1722(ra) # 80003634 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	658080e7          	jalr	1624(ra) # 800045da <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	f5e080e7          	jalr	-162(ra) # 80005ee8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	e5a080e7          	jalr	-422(ra) # 80001dec <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	8ef72423          	sw	a5,-1816(a4) # 80008888 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <print_table>:
  }
}

static void
print_table(pagetable_t pagetable, int level)
{
    80000faa:	7159                	addi	sp,sp,-112
    80000fac:	f486                	sd	ra,104(sp)
    80000fae:	f0a2                	sd	s0,96(sp)
    80000fb0:	eca6                	sd	s1,88(sp)
    80000fb2:	e8ca                	sd	s2,80(sp)
    80000fb4:	e4ce                	sd	s3,72(sp)
    80000fb6:	e0d2                	sd	s4,64(sp)
    80000fb8:	fc56                	sd	s5,56(sp)
    80000fba:	f85a                	sd	s6,48(sp)
    80000fbc:	f45e                	sd	s7,40(sp)
    80000fbe:	f062                	sd	s8,32(sp)
    80000fc0:	ec66                	sd	s9,24(sp)
    80000fc2:	e86a                	sd	s10,16(sp)
    80000fc4:	e46e                	sd	s11,8(sp)
    80000fc6:	1880                	addi	s0,sp,112
    80000fc8:	8cae                	mv	s9,a1

  for(int i = 0; i < 512; i++){
    80000fca:	8a2a                	mv	s4,a0
    80000fcc:	4981                	li	s3,0

    pte_t pte = pagetable[i];
    if (pte & PTE_V) {
      for (int j = 0; j <= level; j++) printf(" ..");

      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80000fce:	00007d17          	auipc	s10,0x7
    80000fd2:	10ad0d13          	addi	s10,s10,266 # 800080d8 <digits+0x98>
    80000fd6:	00158a9b          	addiw	s5,a1,1
      for (int j = 0; j <= level; j++) printf(" ..");
    80000fda:	4d81                	li	s11,0
    80000fdc:	00007b17          	auipc	s6,0x7
    80000fe0:	0f4b0b13          	addi	s6,s6,244 # 800080d0 <digits+0x90>
    }
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000fe4:	4c05                	li	s8,1
  for(int i = 0; i < 512; i++){
    80000fe6:	20000b93          	li	s7,512
    80000fea:	a01d                	j	80001010 <print_table+0x66>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80000fec:	00a95693          	srli	a3,s2,0xa
    80000ff0:	06b2                	slli	a3,a3,0xc
    80000ff2:	864a                	mv	a2,s2
    80000ff4:	85ce                	mv	a1,s3
    80000ff6:	856a                	mv	a0,s10
    80000ff8:	fffff097          	auipc	ra,0xfffff
    80000ffc:	596080e7          	jalr	1430(ra) # 8000058e <printf>
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001000:	00f97793          	andi	a5,s2,15
    80001004:	03878763          	beq	a5,s8,80001032 <print_table+0x88>
  for(int i = 0; i < 512; i++){
    80001008:	2985                	addiw	s3,s3,1
    8000100a:	0a21                	addi	s4,s4,8
    8000100c:	03798c63          	beq	s3,s7,80001044 <print_table+0x9a>
    pte_t pte = pagetable[i];
    80001010:	000a3903          	ld	s2,0(s4) # fffffffffffff000 <end+0xffffffff7ffdd2e0>
    if (pte & PTE_V) {
    80001014:	00197793          	andi	a5,s2,1
    80001018:	d7e5                	beqz	a5,80001000 <print_table+0x56>
      for (int j = 0; j <= level; j++) printf(" ..");
    8000101a:	fc0cc9e3          	bltz	s9,80000fec <print_table+0x42>
    8000101e:	84ee                	mv	s1,s11
    80001020:	855a                	mv	a0,s6
    80001022:	fffff097          	auipc	ra,0xfffff
    80001026:	56c080e7          	jalr	1388(ra) # 8000058e <printf>
    8000102a:	2485                	addiw	s1,s1,1
    8000102c:	fe9a9ae3          	bne	s5,s1,80001020 <print_table+0x76>
    80001030:	bf75                	j	80000fec <print_table+0x42>

      uint64 child = PTE2PA(pte);
    80001032:	00a95513          	srli	a0,s2,0xa
      print_table((pagetable_t)child, level + 1);
    80001036:	85d6                	mv	a1,s5
    80001038:	0532                	slli	a0,a0,0xc
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	f70080e7          	jalr	-144(ra) # 80000faa <print_table>
    80001042:	b7d9                	j	80001008 <print_table+0x5e>
    }
    
  }
}
    80001044:	70a6                	ld	ra,104(sp)
    80001046:	7406                	ld	s0,96(sp)
    80001048:	64e6                	ld	s1,88(sp)
    8000104a:	6946                	ld	s2,80(sp)
    8000104c:	69a6                	ld	s3,72(sp)
    8000104e:	6a06                	ld	s4,64(sp)
    80001050:	7ae2                	ld	s5,56(sp)
    80001052:	7b42                	ld	s6,48(sp)
    80001054:	7ba2                	ld	s7,40(sp)
    80001056:	7c02                	ld	s8,32(sp)
    80001058:	6ce2                	ld	s9,24(sp)
    8000105a:	6d42                	ld	s10,16(sp)
    8000105c:	6da2                	ld	s11,8(sp)
    8000105e:	6165                	addi	sp,sp,112
    80001060:	8082                	ret

0000000080001062 <kvminithart>:
{
    80001062:	1141                	addi	sp,sp,-16
    80001064:	e422                	sd	s0,8(sp)
    80001066:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001068:	12000073          	sfence.vma
  w_satp(MAKE_SATP(kernel_pagetable));
    8000106c:	00008797          	auipc	a5,0x8
    80001070:	8247b783          	ld	a5,-2012(a5) # 80008890 <kernel_pagetable>
    80001074:	83b1                	srli	a5,a5,0xc
    80001076:	577d                	li	a4,-1
    80001078:	177e                	slli	a4,a4,0x3f
    8000107a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000107c:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001080:	12000073          	sfence.vma
}
    80001084:	6422                	ld	s0,8(sp)
    80001086:	0141                	addi	sp,sp,16
    80001088:	8082                	ret

000000008000108a <walk>:
{
    8000108a:	7139                	addi	sp,sp,-64
    8000108c:	fc06                	sd	ra,56(sp)
    8000108e:	f822                	sd	s0,48(sp)
    80001090:	f426                	sd	s1,40(sp)
    80001092:	f04a                	sd	s2,32(sp)
    80001094:	ec4e                	sd	s3,24(sp)
    80001096:	e852                	sd	s4,16(sp)
    80001098:	e456                	sd	s5,8(sp)
    8000109a:	e05a                	sd	s6,0(sp)
    8000109c:	0080                	addi	s0,sp,64
    8000109e:	84aa                	mv	s1,a0
    800010a0:	89ae                	mv	s3,a1
    800010a2:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010a4:	57fd                	li	a5,-1
    800010a6:	83e9                	srli	a5,a5,0x1a
    800010a8:	4a79                	li	s4,30
  for(int level = 2; level > 0; level--) {
    800010aa:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010ac:	04b7f263          	bgeu	a5,a1,800010f0 <walk+0x66>
    panic("walk");
    800010b0:	00007517          	auipc	a0,0x7
    800010b4:	04050513          	addi	a0,a0,64 # 800080f0 <digits+0xb0>
    800010b8:	fffff097          	auipc	ra,0xfffff
    800010bc:	48c080e7          	jalr	1164(ra) # 80000544 <panic>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010c0:	060a8663          	beqz	s5,8000112c <walk+0xa2>
    800010c4:	00000097          	auipc	ra,0x0
    800010c8:	a36080e7          	jalr	-1482(ra) # 80000afa <kalloc>
    800010cc:	84aa                	mv	s1,a0
    800010ce:	c529                	beqz	a0,80001118 <walk+0x8e>
      memset(pagetable, 0, PGSIZE);
    800010d0:	6605                	lui	a2,0x1
    800010d2:	4581                	li	a1,0
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	c12080e7          	jalr	-1006(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010dc:	00c4d793          	srli	a5,s1,0xc
    800010e0:	07aa                	slli	a5,a5,0xa
    800010e2:	0017e793          	ori	a5,a5,1
    800010e6:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010ea:	3a5d                	addiw	s4,s4,-9
    800010ec:	036a0063          	beq	s4,s6,8000110c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010f0:	0149d933          	srl	s2,s3,s4
    800010f4:	1ff97913          	andi	s2,s2,511
    800010f8:	090e                	slli	s2,s2,0x3
    800010fa:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010fc:	00093483          	ld	s1,0(s2)
    80001100:	0014f793          	andi	a5,s1,1
    80001104:	dfd5                	beqz	a5,800010c0 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001106:	80a9                	srli	s1,s1,0xa
    80001108:	04b2                	slli	s1,s1,0xc
    8000110a:	b7c5                	j	800010ea <walk+0x60>
  return &pagetable[PX(0, va)];
    8000110c:	00c9d513          	srli	a0,s3,0xc
    80001110:	1ff57513          	andi	a0,a0,511
    80001114:	050e                	slli	a0,a0,0x3
    80001116:	9526                	add	a0,a0,s1
}
    80001118:	70e2                	ld	ra,56(sp)
    8000111a:	7442                	ld	s0,48(sp)
    8000111c:	74a2                	ld	s1,40(sp)
    8000111e:	7902                	ld	s2,32(sp)
    80001120:	69e2                	ld	s3,24(sp)
    80001122:	6a42                	ld	s4,16(sp)
    80001124:	6aa2                	ld	s5,8(sp)
    80001126:	6b02                	ld	s6,0(sp)
    80001128:	6121                	addi	sp,sp,64
    8000112a:	8082                	ret
        return 0;
    8000112c:	4501                	li	a0,0
    8000112e:	b7ed                	j	80001118 <walk+0x8e>

0000000080001130 <mappages>:
{
    80001130:	715d                	addi	sp,sp,-80
    80001132:	e486                	sd	ra,72(sp)
    80001134:	e0a2                	sd	s0,64(sp)
    80001136:	fc26                	sd	s1,56(sp)
    80001138:	f84a                	sd	s2,48(sp)
    8000113a:	f44e                	sd	s3,40(sp)
    8000113c:	f052                	sd	s4,32(sp)
    8000113e:	ec56                	sd	s5,24(sp)
    80001140:	e85a                	sd	s6,16(sp)
    80001142:	e45e                	sd	s7,8(sp)
    80001144:	0880                	addi	s0,sp,80
  if(size == 0)
    80001146:	c205                	beqz	a2,80001166 <mappages+0x36>
    80001148:	8aaa                	mv	s5,a0
    8000114a:	8b3a                	mv	s6,a4
  a = PGROUNDDOWN(va);
    8000114c:	77fd                	lui	a5,0xfffff
    8000114e:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    80001152:	15fd                	addi	a1,a1,-1
    80001154:	00c589b3          	add	s3,a1,a2
    80001158:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    8000115c:	8952                	mv	s2,s4
    8000115e:	41468a33          	sub	s4,a3,s4
    a += PGSIZE;
    80001162:	6b85                	lui	s7,0x1
    80001164:	a811                	j	80001178 <mappages+0x48>
    panic("mappages: size");
    80001166:	00007517          	auipc	a0,0x7
    8000116a:	f9250513          	addi	a0,a0,-110 # 800080f8 <digits+0xb8>
    8000116e:	fffff097          	auipc	ra,0xfffff
    80001172:	3d6080e7          	jalr	982(ra) # 80000544 <panic>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
  for(;;){
    80001178:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000117c:	4605                	li	a2,1
    8000117e:	85ca                	mv	a1,s2
    80001180:	8556                	mv	a0,s5
    80001182:	00000097          	auipc	ra,0x0
    80001186:	f08080e7          	jalr	-248(ra) # 8000108a <walk>
    8000118a:	cd19                	beqz	a0,800011a8 <mappages+0x78>
    if(*pte & PTE_V) {
    8000118c:	611c                	ld	a5,0(a0)
    8000118e:	8b85                	andi	a5,a5,1
    80001190:	eb85                	bnez	a5,800011c0 <mappages+0x90>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001192:	80b1                	srli	s1,s1,0xc
    80001194:	04aa                	slli	s1,s1,0xa
    80001196:	0164e4b3          	or	s1,s1,s6
    8000119a:	0014e493          	ori	s1,s1,1
    8000119e:	e104                	sd	s1,0(a0)
    if(a == last)
    800011a0:	fd391be3          	bne	s2,s3,80001176 <mappages+0x46>
  return 0;
    800011a4:	4501                	li	a0,0
    800011a6:	a011                	j	800011aa <mappages+0x7a>
      return -1;
    800011a8:	557d                	li	a0,-1
}
    800011aa:	60a6                	ld	ra,72(sp)
    800011ac:	6406                	ld	s0,64(sp)
    800011ae:	74e2                	ld	s1,56(sp)
    800011b0:	7942                	ld	s2,48(sp)
    800011b2:	79a2                	ld	s3,40(sp)
    800011b4:	7a02                	ld	s4,32(sp)
    800011b6:	6ae2                	ld	s5,24(sp)
    800011b8:	6b42                	ld	s6,16(sp)
    800011ba:	6ba2                	ld	s7,8(sp)
    800011bc:	6161                	addi	sp,sp,80
    800011be:	8082                	ret
      return -1;
    800011c0:	557d                	li	a0,-1
    800011c2:	b7e5                	j	800011aa <mappages+0x7a>

00000000800011c4 <kvmmap>:
{
    800011c4:	1141                	addi	sp,sp,-16
    800011c6:	e406                	sd	ra,8(sp)
    800011c8:	e022                	sd	s0,0(sp)
    800011ca:	0800                	addi	s0,sp,16
    800011cc:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011ce:	86b2                	mv	a3,a2
    800011d0:	863e                	mv	a2,a5
    800011d2:	00000097          	auipc	ra,0x0
    800011d6:	f5e080e7          	jalr	-162(ra) # 80001130 <mappages>
    800011da:	e509                	bnez	a0,800011e4 <kvmmap+0x20>
}
    800011dc:	60a2                	ld	ra,8(sp)
    800011de:	6402                	ld	s0,0(sp)
    800011e0:	0141                	addi	sp,sp,16
    800011e2:	8082                	ret
    panic("kvmmap");
    800011e4:	00007517          	auipc	a0,0x7
    800011e8:	f2450513          	addi	a0,a0,-220 # 80008108 <digits+0xc8>
    800011ec:	fffff097          	auipc	ra,0xfffff
    800011f0:	358080e7          	jalr	856(ra) # 80000544 <panic>

00000000800011f4 <kvmmake>:
{
    800011f4:	1101                	addi	sp,sp,-32
    800011f6:	ec06                	sd	ra,24(sp)
    800011f8:	e822                	sd	s0,16(sp)
    800011fa:	e426                	sd	s1,8(sp)
    800011fc:	e04a                	sd	s2,0(sp)
    800011fe:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001200:	00000097          	auipc	ra,0x0
    80001204:	8fa080e7          	jalr	-1798(ra) # 80000afa <kalloc>
    80001208:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000120a:	6605                	lui	a2,0x1
    8000120c:	4581                	li	a1,0
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	ad8080e7          	jalr	-1320(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	6685                	lui	a3,0x1
    8000121a:	10000637          	lui	a2,0x10000
    8000121e:	100005b7          	lui	a1,0x10000
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	fa0080e7          	jalr	-96(ra) # 800011c4 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000122c:	4719                	li	a4,6
    8000122e:	6685                	lui	a3,0x1
    80001230:	10001637          	lui	a2,0x10001
    80001234:	100015b7          	lui	a1,0x10001
    80001238:	8526                	mv	a0,s1
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	f8a080e7          	jalr	-118(ra) # 800011c4 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001242:	4719                	li	a4,6
    80001244:	004006b7          	lui	a3,0x400
    80001248:	0c000637          	lui	a2,0xc000
    8000124c:	0c0005b7          	lui	a1,0xc000
    80001250:	8526                	mv	a0,s1
    80001252:	00000097          	auipc	ra,0x0
    80001256:	f72080e7          	jalr	-142(ra) # 800011c4 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000125a:	00007917          	auipc	s2,0x7
    8000125e:	da690913          	addi	s2,s2,-602 # 80008000 <etext>
    80001262:	4729                	li	a4,10
    80001264:	80007697          	auipc	a3,0x80007
    80001268:	d9c68693          	addi	a3,a3,-612 # 8000 <_entry-0x7fff8000>
    8000126c:	4605                	li	a2,1
    8000126e:	067e                	slli	a2,a2,0x1f
    80001270:	85b2                	mv	a1,a2
    80001272:	8526                	mv	a0,s1
    80001274:	00000097          	auipc	ra,0x0
    80001278:	f50080e7          	jalr	-176(ra) # 800011c4 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000127c:	4719                	li	a4,6
    8000127e:	46c5                	li	a3,17
    80001280:	06ee                	slli	a3,a3,0x1b
    80001282:	412686b3          	sub	a3,a3,s2
    80001286:	864a                	mv	a2,s2
    80001288:	85ca                	mv	a1,s2
    8000128a:	8526                	mv	a0,s1
    8000128c:	00000097          	auipc	ra,0x0
    80001290:	f38080e7          	jalr	-200(ra) # 800011c4 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001294:	4729                	li	a4,10
    80001296:	6685                	lui	a3,0x1
    80001298:	00006617          	auipc	a2,0x6
    8000129c:	d6860613          	addi	a2,a2,-664 # 80007000 <_trampoline>
    800012a0:	040005b7          	lui	a1,0x4000
    800012a4:	15fd                	addi	a1,a1,-1
    800012a6:	05b2                	slli	a1,a1,0xc
    800012a8:	8526                	mv	a0,s1
    800012aa:	00000097          	auipc	ra,0x0
    800012ae:	f1a080e7          	jalr	-230(ra) # 800011c4 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012b2:	8526                	mv	a0,s1
    800012b4:	00000097          	auipc	ra,0x0
    800012b8:	6ea080e7          	jalr	1770(ra) # 8000199e <proc_mapstacks>
}
    800012bc:	8526                	mv	a0,s1
    800012be:	60e2                	ld	ra,24(sp)
    800012c0:	6442                	ld	s0,16(sp)
    800012c2:	64a2                	ld	s1,8(sp)
    800012c4:	6902                	ld	s2,0(sp)
    800012c6:	6105                	addi	sp,sp,32
    800012c8:	8082                	ret

00000000800012ca <kvminit>:
{
    800012ca:	1141                	addi	sp,sp,-16
    800012cc:	e406                	sd	ra,8(sp)
    800012ce:	e022                	sd	s0,0(sp)
    800012d0:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f22080e7          	jalr	-222(ra) # 800011f4 <kvmmake>
    800012da:	00007797          	auipc	a5,0x7
    800012de:	5aa7bb23          	sd	a0,1462(a5) # 80008890 <kernel_pagetable>
}
    800012e2:	60a2                	ld	ra,8(sp)
    800012e4:	6402                	ld	s0,0(sp)
    800012e6:	0141                	addi	sp,sp,16
    800012e8:	8082                	ret

00000000800012ea <uvmunmap>:
{
    800012ea:	715d                	addi	sp,sp,-80
    800012ec:	e486                	sd	ra,72(sp)
    800012ee:	e0a2                	sd	s0,64(sp)
    800012f0:	fc26                	sd	s1,56(sp)
    800012f2:	f84a                	sd	s2,48(sp)
    800012f4:	f44e                	sd	s3,40(sp)
    800012f6:	f052                	sd	s4,32(sp)
    800012f8:	ec56                	sd	s5,24(sp)
    800012fa:	e85a                	sd	s6,16(sp)
    800012fc:	e45e                	sd	s7,8(sp)
    800012fe:	0880                	addi	s0,sp,80
  if((va % PGSIZE) != 0)
    80001300:	03459793          	slli	a5,a1,0x34
    80001304:	e795                	bnez	a5,80001330 <uvmunmap+0x46>
    80001306:	8a2a                	mv	s4,a0
    80001308:	892e                	mv	s2,a1
    8000130a:	8b36                	mv	s6,a3
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	0632                	slli	a2,a2,0xc
    8000130e:	00b609b3          	add	s3,a2,a1
        if(PTE_FLAGS(*pte) == PTE_V)
    80001312:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001314:	6a85                	lui	s5,0x1
    80001316:	0535e263          	bltu	a1,s3,8000135a <uvmunmap+0x70>
}
    8000131a:	60a6                	ld	ra,72(sp)
    8000131c:	6406                	ld	s0,64(sp)
    8000131e:	74e2                	ld	s1,56(sp)
    80001320:	7942                	ld	s2,48(sp)
    80001322:	79a2                	ld	s3,40(sp)
    80001324:	7a02                	ld	s4,32(sp)
    80001326:	6ae2                	ld	s5,24(sp)
    80001328:	6b42                	ld	s6,16(sp)
    8000132a:	6ba2                	ld	s7,8(sp)
    8000132c:	6161                	addi	sp,sp,80
    8000132e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001330:	00007517          	auipc	a0,0x7
    80001334:	de050513          	addi	a0,a0,-544 # 80008110 <digits+0xd0>
    80001338:	fffff097          	auipc	ra,0xfffff
    8000133c:	20c080e7          	jalr	524(ra) # 80000544 <panic>
          panic("uvmunmap: not a leaf");
    80001340:	00007517          	auipc	a0,0x7
    80001344:	de850513          	addi	a0,a0,-536 # 80008128 <digits+0xe8>
    80001348:	fffff097          	auipc	ra,0xfffff
    8000134c:	1fc080e7          	jalr	508(ra) # 80000544 <panic>
      *pte = 0;
    80001350:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001354:	9956                	add	s2,s2,s5
    80001356:	fd3972e3          	bgeu	s2,s3,8000131a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0) 
    8000135a:	4601                	li	a2,0
    8000135c:	85ca                	mv	a1,s2
    8000135e:	8552                	mv	a0,s4
    80001360:	00000097          	auipc	ra,0x0
    80001364:	d2a080e7          	jalr	-726(ra) # 8000108a <walk>
    80001368:	84aa                	mv	s1,a0
    8000136a:	d56d                	beqz	a0,80001354 <uvmunmap+0x6a>
      if((*pte & PTE_V) == 0){
    8000136c:	611c                	ld	a5,0(a0)
    8000136e:	0017f713          	andi	a4,a5,1
    80001372:	df79                	beqz	a4,80001350 <uvmunmap+0x66>
        if(PTE_FLAGS(*pte) == PTE_V)
    80001374:	3ff7f713          	andi	a4,a5,1023
    80001378:	fd7704e3          	beq	a4,s7,80001340 <uvmunmap+0x56>
        if(do_free){
    8000137c:	fc0b0ae3          	beqz	s6,80001350 <uvmunmap+0x66>
          uint64 pa = PTE2PA(*pte);
    80001380:	83a9                	srli	a5,a5,0xa
          kfree((void*)pa);
    80001382:	00c79513          	slli	a0,a5,0xc
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	678080e7          	jalr	1656(ra) # 800009fe <kfree>
    8000138e:	b7c9                	j	80001350 <uvmunmap+0x66>

0000000080001390 <uvmcreate>:
{
    80001390:	1101                	addi	sp,sp,-32
    80001392:	ec06                	sd	ra,24(sp)
    80001394:	e822                	sd	s0,16(sp)
    80001396:	e426                	sd	s1,8(sp)
    80001398:	1000                	addi	s0,sp,32
  pagetable = (pagetable_t) kalloc();
    8000139a:	fffff097          	auipc	ra,0xfffff
    8000139e:	760080e7          	jalr	1888(ra) # 80000afa <kalloc>
    800013a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a4:	c519                	beqz	a0,800013b2 <uvmcreate+0x22>
  memset(pagetable, 0, PGSIZE);
    800013a6:	6605                	lui	a2,0x1
    800013a8:	4581                	li	a1,0
    800013aa:	00000097          	auipc	ra,0x0
    800013ae:	93c080e7          	jalr	-1732(ra) # 80000ce6 <memset>
}
    800013b2:	8526                	mv	a0,s1
    800013b4:	60e2                	ld	ra,24(sp)
    800013b6:	6442                	ld	s0,16(sp)
    800013b8:	64a2                	ld	s1,8(sp)
    800013ba:	6105                	addi	sp,sp,32
    800013bc:	8082                	ret

00000000800013be <uvmfirst>:
{
    800013be:	7179                	addi	sp,sp,-48
    800013c0:	f406                	sd	ra,40(sp)
    800013c2:	f022                	sd	s0,32(sp)
    800013c4:	ec26                	sd	s1,24(sp)
    800013c6:	e84a                	sd	s2,16(sp)
    800013c8:	e44e                	sd	s3,8(sp)
    800013ca:	e052                	sd	s4,0(sp)
    800013cc:	1800                	addi	s0,sp,48
  if(sz >= PGSIZE)
    800013ce:	6785                	lui	a5,0x1
    800013d0:	04f67863          	bgeu	a2,a5,80001420 <uvmfirst+0x62>
    800013d4:	8a2a                	mv	s4,a0
    800013d6:	89ae                	mv	s3,a1
    800013d8:	84b2                	mv	s1,a2
  mem = kalloc();
    800013da:	fffff097          	auipc	ra,0xfffff
    800013de:	720080e7          	jalr	1824(ra) # 80000afa <kalloc>
    800013e2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e4:	6605                	lui	a2,0x1
    800013e6:	4581                	li	a1,0
    800013e8:	00000097          	auipc	ra,0x0
    800013ec:	8fe080e7          	jalr	-1794(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013f0:	4779                	li	a4,30
    800013f2:	86ca                	mv	a3,s2
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	8552                	mv	a0,s4
    800013fa:	00000097          	auipc	ra,0x0
    800013fe:	d36080e7          	jalr	-714(ra) # 80001130 <mappages>
  memmove(mem, src, sz);
    80001402:	8626                	mv	a2,s1
    80001404:	85ce                	mv	a1,s3
    80001406:	854a                	mv	a0,s2
    80001408:	00000097          	auipc	ra,0x0
    8000140c:	93e080e7          	jalr	-1730(ra) # 80000d46 <memmove>
}
    80001410:	70a2                	ld	ra,40(sp)
    80001412:	7402                	ld	s0,32(sp)
    80001414:	64e2                	ld	s1,24(sp)
    80001416:	6942                	ld	s2,16(sp)
    80001418:	69a2                	ld	s3,8(sp)
    8000141a:	6a02                	ld	s4,0(sp)
    8000141c:	6145                	addi	sp,sp,48
    8000141e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001420:	00007517          	auipc	a0,0x7
    80001424:	d2050513          	addi	a0,a0,-736 # 80008140 <digits+0x100>
    80001428:	fffff097          	auipc	ra,0xfffff
    8000142c:	11c080e7          	jalr	284(ra) # 80000544 <panic>

0000000080001430 <uvmdealloc>:
{
    80001430:	1101                	addi	sp,sp,-32
    80001432:	ec06                	sd	ra,24(sp)
    80001434:	e822                	sd	s0,16(sp)
    80001436:	e426                	sd	s1,8(sp)
    80001438:	1000                	addi	s0,sp,32
    return oldsz;
    8000143a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000143c:	00b67d63          	bgeu	a2,a1,80001456 <uvmdealloc+0x26>
    80001440:	84b2                	mv	s1,a2
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001442:	6785                	lui	a5,0x1
    80001444:	17fd                	addi	a5,a5,-1
    80001446:	00f60733          	add	a4,a2,a5
    8000144a:	767d                	lui	a2,0xfffff
    8000144c:	8f71                	and	a4,a4,a2
    8000144e:	97ae                	add	a5,a5,a1
    80001450:	8ff1                	and	a5,a5,a2
    80001452:	00f76863          	bltu	a4,a5,80001462 <uvmdealloc+0x32>
}
    80001456:	8526                	mv	a0,s1
    80001458:	60e2                	ld	ra,24(sp)
    8000145a:	6442                	ld	s0,16(sp)
    8000145c:	64a2                	ld	s1,8(sp)
    8000145e:	6105                	addi	sp,sp,32
    80001460:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001462:	8f99                	sub	a5,a5,a4
    80001464:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001466:	4685                	li	a3,1
    80001468:	0007861b          	sext.w	a2,a5
    8000146c:	85ba                	mv	a1,a4
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	e7c080e7          	jalr	-388(ra) # 800012ea <uvmunmap>
    80001476:	b7c5                	j	80001456 <uvmdealloc+0x26>

0000000080001478 <uvmalloc>:
  if(newsz < oldsz)
    80001478:	0ab66563          	bltu	a2,a1,80001522 <uvmalloc+0xaa>
{
    8000147c:	7139                	addi	sp,sp,-64
    8000147e:	fc06                	sd	ra,56(sp)
    80001480:	f822                	sd	s0,48(sp)
    80001482:	f426                	sd	s1,40(sp)
    80001484:	f04a                	sd	s2,32(sp)
    80001486:	ec4e                	sd	s3,24(sp)
    80001488:	e852                	sd	s4,16(sp)
    8000148a:	e456                	sd	s5,8(sp)
    8000148c:	e05a                	sd	s6,0(sp)
    8000148e:	0080                	addi	s0,sp,64
    80001490:	8aaa                	mv	s5,a0
    80001492:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001494:	6985                	lui	s3,0x1
    80001496:	19fd                	addi	s3,s3,-1
    80001498:	95ce                	add	a1,a1,s3
    8000149a:	79fd                	lui	s3,0xfffff
    8000149c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a0:	08c9f363          	bgeu	s3,a2,80001526 <uvmalloc+0xae>
    800014a4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	650080e7          	jalr	1616(ra) # 80000afa <kalloc>
    800014b2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b4:	c51d                	beqz	a0,800014e2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014b6:	6605                	lui	a2,0x1
    800014b8:	4581                	li	a1,0
    800014ba:	00000097          	auipc	ra,0x0
    800014be:	82c080e7          	jalr	-2004(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014c2:	875a                	mv	a4,s6
    800014c4:	86a6                	mv	a3,s1
    800014c6:	6605                	lui	a2,0x1
    800014c8:	85ca                	mv	a1,s2
    800014ca:	8556                	mv	a0,s5
    800014cc:	00000097          	auipc	ra,0x0
    800014d0:	c64080e7          	jalr	-924(ra) # 80001130 <mappages>
    800014d4:	e90d                	bnez	a0,80001506 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d6:	6785                	lui	a5,0x1
    800014d8:	993e                	add	s2,s2,a5
    800014da:	fd4968e3          	bltu	s2,s4,800014aa <uvmalloc+0x32>
  return newsz;
    800014de:	8552                	mv	a0,s4
    800014e0:	a809                	j	800014f2 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014e2:	864e                	mv	a2,s3
    800014e4:	85ca                	mv	a1,s2
    800014e6:	8556                	mv	a0,s5
    800014e8:	00000097          	auipc	ra,0x0
    800014ec:	f48080e7          	jalr	-184(ra) # 80001430 <uvmdealloc>
      return 0;
    800014f0:	4501                	li	a0,0
}
    800014f2:	70e2                	ld	ra,56(sp)
    800014f4:	7442                	ld	s0,48(sp)
    800014f6:	74a2                	ld	s1,40(sp)
    800014f8:	7902                	ld	s2,32(sp)
    800014fa:	69e2                	ld	s3,24(sp)
    800014fc:	6a42                	ld	s4,16(sp)
    800014fe:	6aa2                	ld	s5,8(sp)
    80001500:	6b02                	ld	s6,0(sp)
    80001502:	6121                	addi	sp,sp,64
    80001504:	8082                	ret
      kfree(mem);
    80001506:	8526                	mv	a0,s1
    80001508:	fffff097          	auipc	ra,0xfffff
    8000150c:	4f6080e7          	jalr	1270(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001510:	864e                	mv	a2,s3
    80001512:	85ca                	mv	a1,s2
    80001514:	8556                	mv	a0,s5
    80001516:	00000097          	auipc	ra,0x0
    8000151a:	f1a080e7          	jalr	-230(ra) # 80001430 <uvmdealloc>
      return 0;
    8000151e:	4501                	li	a0,0
    80001520:	bfc9                	j	800014f2 <uvmalloc+0x7a>
    return oldsz;
    80001522:	852e                	mv	a0,a1
}
    80001524:	8082                	ret
  return newsz;
    80001526:	8532                	mv	a0,a2
    80001528:	b7e9                	j	800014f2 <uvmalloc+0x7a>

000000008000152a <freewalk>:
{
    8000152a:	7179                	addi	sp,sp,-48
    8000152c:	f406                	sd	ra,40(sp)
    8000152e:	f022                	sd	s0,32(sp)
    80001530:	ec26                	sd	s1,24(sp)
    80001532:	e84a                	sd	s2,16(sp)
    80001534:	e44e                	sd	s3,8(sp)
    80001536:	e052                	sd	s4,0(sp)
    80001538:	1800                	addi	s0,sp,48
    8000153a:	8a2a                	mv	s4,a0
  for(int i = 0; i < 512; i++){
    8000153c:	84aa                	mv	s1,a0
    8000153e:	6905                	lui	s2,0x1
    80001540:	992a                	add	s2,s2,a0
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001542:	4985                	li	s3,1
    80001544:	a821                	j	8000155c <freewalk+0x32>
      uint64 child = PTE2PA(pte);
    80001546:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001548:	0532                	slli	a0,a0,0xc
    8000154a:	00000097          	auipc	ra,0x0
    8000154e:	fe0080e7          	jalr	-32(ra) # 8000152a <freewalk>
      pagetable[i] = 0;
    80001552:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001556:	04a1                	addi	s1,s1,8
    80001558:	03248163          	beq	s1,s2,8000157a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000155c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000155e:	00f57793          	andi	a5,a0,15
    80001562:	ff3782e3          	beq	a5,s3,80001546 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001566:	8905                	andi	a0,a0,1
    80001568:	d57d                	beqz	a0,80001556 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000156a:	00007517          	auipc	a0,0x7
    8000156e:	bf650513          	addi	a0,a0,-1034 # 80008160 <digits+0x120>
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	fd2080e7          	jalr	-46(ra) # 80000544 <panic>
  kfree((void*)pagetable);
    8000157a:	8552                	mv	a0,s4
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	482080e7          	jalr	1154(ra) # 800009fe <kfree>
}
    80001584:	70a2                	ld	ra,40(sp)
    80001586:	7402                	ld	s0,32(sp)
    80001588:	64e2                	ld	s1,24(sp)
    8000158a:	6942                	ld	s2,16(sp)
    8000158c:	69a2                	ld	s3,8(sp)
    8000158e:	6a02                	ld	s4,0(sp)
    80001590:	6145                	addi	sp,sp,48
    80001592:	8082                	ret

0000000080001594 <uvmfree>:
{
    80001594:	1101                	addi	sp,sp,-32
    80001596:	ec06                	sd	ra,24(sp)
    80001598:	e822                	sd	s0,16(sp)
    8000159a:	e426                	sd	s1,8(sp)
    8000159c:	1000                	addi	s0,sp,32
    8000159e:	84aa                	mv	s1,a0
  if(sz > 0)
    800015a0:	e999                	bnez	a1,800015b6 <uvmfree+0x22>
  freewalk(pagetable);
    800015a2:	8526                	mv	a0,s1
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	f86080e7          	jalr	-122(ra) # 8000152a <freewalk>
}
    800015ac:	60e2                	ld	ra,24(sp)
    800015ae:	6442                	ld	s0,16(sp)
    800015b0:	64a2                	ld	s1,8(sp)
    800015b2:	6105                	addi	sp,sp,32
    800015b4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b6:	6605                	lui	a2,0x1
    800015b8:	167d                	addi	a2,a2,-1
    800015ba:	962e                	add	a2,a2,a1
    800015bc:	4685                	li	a3,1
    800015be:	8231                	srli	a2,a2,0xc
    800015c0:	4581                	li	a1,0
    800015c2:	00000097          	auipc	ra,0x0
    800015c6:	d28080e7          	jalr	-728(ra) # 800012ea <uvmunmap>
    800015ca:	bfe1                	j	800015a2 <uvmfree+0xe>

00000000800015cc <uvmcopy>:
  for(i = 0; i < sz; i += PGSIZE){
    800015cc:	ca4d                	beqz	a2,8000167e <uvmcopy+0xb2>
{
    800015ce:	715d                	addi	sp,sp,-80
    800015d0:	e486                	sd	ra,72(sp)
    800015d2:	e0a2                	sd	s0,64(sp)
    800015d4:	fc26                	sd	s1,56(sp)
    800015d6:	f84a                	sd	s2,48(sp)
    800015d8:	f44e                	sd	s3,40(sp)
    800015da:	f052                	sd	s4,32(sp)
    800015dc:	ec56                	sd	s5,24(sp)
    800015de:	e85a                	sd	s6,16(sp)
    800015e0:	e45e                	sd	s7,8(sp)
    800015e2:	0880                	addi	s0,sp,80
    800015e4:	8aaa                	mv	s5,a0
    800015e6:	8b2e                	mv	s6,a1
    800015e8:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ea:	4481                	li	s1,0
    800015ec:	a029                	j	800015f6 <uvmcopy+0x2a>
    800015ee:	6785                	lui	a5,0x1
    800015f0:	94be                	add	s1,s1,a5
    800015f2:	0744fa63          	bgeu	s1,s4,80001666 <uvmcopy+0x9a>
     if((pte = walk(old, i, 0)) == 0) {
    800015f6:	4601                	li	a2,0
    800015f8:	85a6                	mv	a1,s1
    800015fa:	8556                	mv	a0,s5
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	a8e080e7          	jalr	-1394(ra) # 8000108a <walk>
    80001604:	d56d                	beqz	a0,800015ee <uvmcopy+0x22>
    } if((*pte & PTE_V) == 0) {
    80001606:	6118                	ld	a4,0(a0)
    80001608:	00177793          	andi	a5,a4,1
    8000160c:	d3ed                	beqz	a5,800015ee <uvmcopy+0x22>
    pa = PTE2PA(*pte);
    8000160e:	00a75593          	srli	a1,a4,0xa
    80001612:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001616:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000161a:	fffff097          	auipc	ra,0xfffff
    8000161e:	4e0080e7          	jalr	1248(ra) # 80000afa <kalloc>
    80001622:	89aa                	mv	s3,a0
    80001624:	c515                	beqz	a0,80001650 <uvmcopy+0x84>
    memmove(mem, (char*)pa, PGSIZE);
    80001626:	6605                	lui	a2,0x1
    80001628:	85de                	mv	a1,s7
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	71c080e7          	jalr	1820(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001632:	874a                	mv	a4,s2
    80001634:	86ce                	mv	a3,s3
    80001636:	6605                	lui	a2,0x1
    80001638:	85a6                	mv	a1,s1
    8000163a:	855a                	mv	a0,s6
    8000163c:	00000097          	auipc	ra,0x0
    80001640:	af4080e7          	jalr	-1292(ra) # 80001130 <mappages>
    80001644:	d54d                	beqz	a0,800015ee <uvmcopy+0x22>
      kfree(mem);
    80001646:	854e                	mv	a0,s3
    80001648:	fffff097          	auipc	ra,0xfffff
    8000164c:	3b6080e7          	jalr	950(ra) # 800009fe <kfree>
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001650:	4685                	li	a3,1
    80001652:	00c4d613          	srli	a2,s1,0xc
    80001656:	4581                	li	a1,0
    80001658:	855a                	mv	a0,s6
    8000165a:	00000097          	auipc	ra,0x0
    8000165e:	c90080e7          	jalr	-880(ra) # 800012ea <uvmunmap>
  return -1;
    80001662:	557d                	li	a0,-1
    80001664:	a011                	j	80001668 <uvmcopy+0x9c>
  return 0;
    80001666:	4501                	li	a0,0
}
    80001668:	60a6                	ld	ra,72(sp)
    8000166a:	6406                	ld	s0,64(sp)
    8000166c:	74e2                	ld	s1,56(sp)
    8000166e:	7942                	ld	s2,48(sp)
    80001670:	79a2                	ld	s3,40(sp)
    80001672:	7a02                	ld	s4,32(sp)
    80001674:	6ae2                	ld	s5,24(sp)
    80001676:	6b42                	ld	s6,16(sp)
    80001678:	6ba2                	ld	s7,8(sp)
    8000167a:	6161                	addi	sp,sp,80
    8000167c:	8082                	ret
  return 0;
    8000167e:	4501                	li	a0,0
}
    80001680:	8082                	ret

0000000080001682 <uvmclear>:
{
    80001682:	1141                	addi	sp,sp,-16
    80001684:	e406                	sd	ra,8(sp)
    80001686:	e022                	sd	s0,0(sp)
    80001688:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000168a:	4601                	li	a2,0
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	9fe080e7          	jalr	-1538(ra) # 8000108a <walk>
  if(pte == 0)
    80001694:	c901                	beqz	a0,800016a4 <uvmclear+0x22>
  *pte &= ~PTE_U;
    80001696:	611c                	ld	a5,0(a0)
    80001698:	9bbd                	andi	a5,a5,-17
    8000169a:	e11c                	sd	a5,0(a0)
}
    8000169c:	60a2                	ld	ra,8(sp)
    8000169e:	6402                	ld	s0,0(sp)
    800016a0:	0141                	addi	sp,sp,16
    800016a2:	8082                	ret
    panic("uvmclear");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	acc50513          	addi	a0,a0,-1332 # 80008170 <digits+0x130>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	e98080e7          	jalr	-360(ra) # 80000544 <panic>

00000000800016b4 <vmprint>:

void vmprint(pagetable_t pagetable) {
    800016b4:	1101                	addi	sp,sp,-32
    800016b6:	ec06                	sd	ra,24(sp)
    800016b8:	e822                	sd	s0,16(sp)
    800016ba:	e426                	sd	s1,8(sp)
    800016bc:	1000                	addi	s0,sp,32
    800016be:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800016c0:	85aa                	mv	a1,a0
    800016c2:	00007517          	auipc	a0,0x7
    800016c6:	abe50513          	addi	a0,a0,-1346 # 80008180 <digits+0x140>
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	ec4080e7          	jalr	-316(ra) # 8000058e <printf>
  print_table(pagetable, 0);
    800016d2:	4581                	li	a1,0
    800016d4:	8526                	mv	a0,s1
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	8d4080e7          	jalr	-1836(ra) # 80000faa <print_table>
}
    800016de:	60e2                	ld	ra,24(sp)
    800016e0:	6442                	ld	s0,16(sp)
    800016e2:	64a2                	ld	s1,8(sp)
    800016e4:	6105                	addi	sp,sp,32
    800016e6:	8082                	ret

00000000800016e8 <print>:

void print(pagetable_t pagetable) { vmprint(pagetable); }
    800016e8:	1141                	addi	sp,sp,-16
    800016ea:	e406                	sd	ra,8(sp)
    800016ec:	e022                	sd	s0,0(sp)
    800016ee:	0800                	addi	s0,sp,16
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	fc4080e7          	jalr	-60(ra) # 800016b4 <vmprint>
    800016f8:	60a2                	ld	ra,8(sp)
    800016fa:	6402                	ld	s0,0(sp)
    800016fc:	0141                	addi	sp,sp,16
    800016fe:	8082                	ret

0000000080001700 <lazyalloc>:

uint64 lazyalloc(struct proc * p, uint64 va){
    80001700:	7179                	addi	sp,sp,-48
    80001702:	f406                	sd	ra,40(sp)
    80001704:	f022                	sd	s0,32(sp)
    80001706:	ec26                	sd	s1,24(sp)
    80001708:	e84a                	sd	s2,16(sp)
    8000170a:	e44e                	sd	s3,8(sp)
    8000170c:	e052                	sd	s4,0(sp)
    8000170e:	1800                	addi	s0,sp,48

  if(va >= p->sz || va < PGROUNDUP(p->trapframe->sp)) return 0;
    80001710:	653c                	ld	a5,72(a0)
    80001712:	4981                	li	s3,0
    80001714:	00f5fe63          	bgeu	a1,a5,80001730 <lazyalloc+0x30>
    80001718:	84aa                	mv	s1,a0
    8000171a:	892e                	mv	s2,a1
    8000171c:	6d3c                	ld	a5,88(a0)
    8000171e:	7b9c                	ld	a5,48(a5)
    80001720:	6705                	lui	a4,0x1
    80001722:	177d                	addi	a4,a4,-1
    80001724:	97ba                	add	a5,a5,a4
    80001726:	777d                	lui	a4,0xfffff
    80001728:	8ff9                	and	a5,a5,a4
    8000172a:	4981                	li	s3,0
    8000172c:	00f5fb63          	bgeu	a1,a5,80001742 <lazyalloc+0x42>
      kfree(mem);
      return 0;
    }

  return (uint64)mem;
}
    80001730:	854e                	mv	a0,s3
    80001732:	70a2                	ld	ra,40(sp)
    80001734:	7402                	ld	s0,32(sp)
    80001736:	64e2                	ld	s1,24(sp)
    80001738:	6942                	ld	s2,16(sp)
    8000173a:	69a2                	ld	s3,8(sp)
    8000173c:	6a02                	ld	s4,0(sp)
    8000173e:	6145                	addi	sp,sp,48
    80001740:	8082                	ret
  mem = kalloc();
    80001742:	fffff097          	auipc	ra,0xfffff
    80001746:	3b8080e7          	jalr	952(ra) # 80000afa <kalloc>
    8000174a:	8a2a                	mv	s4,a0
  if(mem == 0)return 0;
    8000174c:	d175                	beqz	a0,80001730 <lazyalloc+0x30>
  memset(mem, 0, PGSIZE);  
    8000174e:	6605                	lui	a2,0x1
    80001750:	4581                	li	a1,0
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	594080e7          	jalr	1428(ra) # 80000ce6 <memset>
    if(mappages(p->pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000175a:	89d2                	mv	s3,s4
    8000175c:	4779                	li	a4,30
    8000175e:	86d2                	mv	a3,s4
    80001760:	6605                	lui	a2,0x1
    80001762:	75fd                	lui	a1,0xfffff
    80001764:	00b975b3          	and	a1,s2,a1
    80001768:	68a8                	ld	a0,80(s1)
    8000176a:	00000097          	auipc	ra,0x0
    8000176e:	9c6080e7          	jalr	-1594(ra) # 80001130 <mappages>
    80001772:	dd5d                	beqz	a0,80001730 <lazyalloc+0x30>
      kfree(mem);
    80001774:	8552                	mv	a0,s4
    80001776:	fffff097          	auipc	ra,0xfffff
    8000177a:	288080e7          	jalr	648(ra) # 800009fe <kfree>
      return 0;
    8000177e:	4981                	li	s3,0
    80001780:	bf45                	j	80001730 <lazyalloc+0x30>

0000000080001782 <walkaddr>:
  if(va >= MAXVA){
    80001782:	57fd                	li	a5,-1
    80001784:	83e9                	srli	a5,a5,0x1a
    80001786:	00b7f463          	bgeu	a5,a1,8000178e <walkaddr+0xc>
    return 0;
    8000178a:	4501                	li	a0,0
}
    8000178c:	8082                	ret
{
    8000178e:	1101                	addi	sp,sp,-32
    80001790:	ec06                	sd	ra,24(sp)
    80001792:	e822                	sd	s0,16(sp)
    80001794:	e426                	sd	s1,8(sp)
    80001796:	1000                	addi	s0,sp,32
    80001798:	84ae                	mv	s1,a1
  pte = walk(pagetable, va, 0);
    8000179a:	4601                	li	a2,0
    8000179c:	00000097          	auipc	ra,0x0
    800017a0:	8ee080e7          	jalr	-1810(ra) # 8000108a <walk>
  if(pte == 0)
    800017a4:	c909                	beqz	a0,800017b6 <walkaddr+0x34>
  if((*pte & PTE_V) == 0)
    800017a6:	6108                	ld	a0,0(a0)
  if((*pte & PTE_U) == 0)
    800017a8:	01157713          	andi	a4,a0,17
    800017ac:	47c5                	li	a5,17
  pa = PTE2PA(*pte);
    800017ae:	8129                	srli	a0,a0,0xa
    800017b0:	0532                	slli	a0,a0,0xc
  if((*pte & PTE_U) == 0)
    800017b2:	00f70b63          	beq	a4,a5,800017c8 <walkaddr+0x46>
   if ((pa = lazyalloc(myproc(), va)) <= 0)
    800017b6:	00000097          	auipc	ra,0x0
    800017ba:	35e080e7          	jalr	862(ra) # 80001b14 <myproc>
    800017be:	85a6                	mv	a1,s1
    800017c0:	00000097          	auipc	ra,0x0
    800017c4:	f40080e7          	jalr	-192(ra) # 80001700 <lazyalloc>
}
    800017c8:	60e2                	ld	ra,24(sp)
    800017ca:	6442                	ld	s0,16(sp)
    800017cc:	64a2                	ld	s1,8(sp)
    800017ce:	6105                	addi	sp,sp,32
    800017d0:	8082                	ret

00000000800017d2 <copyout>:
  while(len > 0){
    800017d2:	c6bd                	beqz	a3,80001840 <copyout+0x6e>
{
    800017d4:	715d                	addi	sp,sp,-80
    800017d6:	e486                	sd	ra,72(sp)
    800017d8:	e0a2                	sd	s0,64(sp)
    800017da:	fc26                	sd	s1,56(sp)
    800017dc:	f84a                	sd	s2,48(sp)
    800017de:	f44e                	sd	s3,40(sp)
    800017e0:	f052                	sd	s4,32(sp)
    800017e2:	ec56                	sd	s5,24(sp)
    800017e4:	e85a                	sd	s6,16(sp)
    800017e6:	e45e                	sd	s7,8(sp)
    800017e8:	e062                	sd	s8,0(sp)
    800017ea:	0880                	addi	s0,sp,80
    800017ec:	8b2a                	mv	s6,a0
    800017ee:	8c2e                	mv	s8,a1
    800017f0:	8a32                	mv	s4,a2
    800017f2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017f4:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (dstva - va0);
    800017f6:	6a85                	lui	s5,0x1
    800017f8:	a015                	j	8000181c <copyout+0x4a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017fa:	9562                	add	a0,a0,s8
    800017fc:	0004861b          	sext.w	a2,s1
    80001800:	85d2                	mv	a1,s4
    80001802:	41250533          	sub	a0,a0,s2
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	540080e7          	jalr	1344(ra) # 80000d46 <memmove>
    len -= n;
    8000180e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001812:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001814:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001818:	02098263          	beqz	s3,8000183c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000181c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001820:	85ca                	mv	a1,s2
    80001822:	855a                	mv	a0,s6
    80001824:	00000097          	auipc	ra,0x0
    80001828:	f5e080e7          	jalr	-162(ra) # 80001782 <walkaddr>
    if(pa0 == 0)
    8000182c:	cd01                	beqz	a0,80001844 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000182e:	418904b3          	sub	s1,s2,s8
    80001832:	94d6                	add	s1,s1,s5
    if(n > len)
    80001834:	fc99f3e3          	bgeu	s3,s1,800017fa <copyout+0x28>
    80001838:	84ce                	mv	s1,s3
    8000183a:	b7c1                	j	800017fa <copyout+0x28>
  return 0;
    8000183c:	4501                	li	a0,0
    8000183e:	a021                	j	80001846 <copyout+0x74>
    80001840:	4501                	li	a0,0
}
    80001842:	8082                	ret
      return -1;
    80001844:	557d                	li	a0,-1
}
    80001846:	60a6                	ld	ra,72(sp)
    80001848:	6406                	ld	s0,64(sp)
    8000184a:	74e2                	ld	s1,56(sp)
    8000184c:	7942                	ld	s2,48(sp)
    8000184e:	79a2                	ld	s3,40(sp)
    80001850:	7a02                	ld	s4,32(sp)
    80001852:	6ae2                	ld	s5,24(sp)
    80001854:	6b42                	ld	s6,16(sp)
    80001856:	6ba2                	ld	s7,8(sp)
    80001858:	6c02                	ld	s8,0(sp)
    8000185a:	6161                	addi	sp,sp,80
    8000185c:	8082                	ret

000000008000185e <copyin>:
  while(len > 0){
    8000185e:	c6bd                	beqz	a3,800018cc <copyin+0x6e>
{
    80001860:	715d                	addi	sp,sp,-80
    80001862:	e486                	sd	ra,72(sp)
    80001864:	e0a2                	sd	s0,64(sp)
    80001866:	fc26                	sd	s1,56(sp)
    80001868:	f84a                	sd	s2,48(sp)
    8000186a:	f44e                	sd	s3,40(sp)
    8000186c:	f052                	sd	s4,32(sp)
    8000186e:	ec56                	sd	s5,24(sp)
    80001870:	e85a                	sd	s6,16(sp)
    80001872:	e45e                	sd	s7,8(sp)
    80001874:	e062                	sd	s8,0(sp)
    80001876:	0880                	addi	s0,sp,80
    80001878:	8b2a                	mv	s6,a0
    8000187a:	8a2e                	mv	s4,a1
    8000187c:	8c32                	mv	s8,a2
    8000187e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001880:	7bfd                	lui	s7,0xfffff
    n = PGSIZE - (srcva - va0);
    80001882:	6a85                	lui	s5,0x1
    80001884:	a015                	j	800018a8 <copyin+0x4a>
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001886:	9562                	add	a0,a0,s8
    80001888:	0004861b          	sext.w	a2,s1
    8000188c:	412505b3          	sub	a1,a0,s2
    80001890:	8552                	mv	a0,s4
    80001892:	fffff097          	auipc	ra,0xfffff
    80001896:	4b4080e7          	jalr	1204(ra) # 80000d46 <memmove>
    len -= n;
    8000189a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000189e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800018a0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018a4:	02098263          	beqz	s3,800018c8 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800018a8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018ac:	85ca                	mv	a1,s2
    800018ae:	855a                	mv	a0,s6
    800018b0:	00000097          	auipc	ra,0x0
    800018b4:	ed2080e7          	jalr	-302(ra) # 80001782 <walkaddr>
    if(pa0 == 0)
    800018b8:	cd01                	beqz	a0,800018d0 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800018ba:	418904b3          	sub	s1,s2,s8
    800018be:	94d6                	add	s1,s1,s5
    if(n > len)
    800018c0:	fc99f3e3          	bgeu	s3,s1,80001886 <copyin+0x28>
    800018c4:	84ce                	mv	s1,s3
    800018c6:	b7c1                	j	80001886 <copyin+0x28>
  return 0;
    800018c8:	4501                	li	a0,0
    800018ca:	a021                	j	800018d2 <copyin+0x74>
    800018cc:	4501                	li	a0,0
}
    800018ce:	8082                	ret
      return -1;
    800018d0:	557d                	li	a0,-1
}
    800018d2:	60a6                	ld	ra,72(sp)
    800018d4:	6406                	ld	s0,64(sp)
    800018d6:	74e2                	ld	s1,56(sp)
    800018d8:	7942                	ld	s2,48(sp)
    800018da:	79a2                	ld	s3,40(sp)
    800018dc:	7a02                	ld	s4,32(sp)
    800018de:	6ae2                	ld	s5,24(sp)
    800018e0:	6b42                	ld	s6,16(sp)
    800018e2:	6ba2                	ld	s7,8(sp)
    800018e4:	6c02                	ld	s8,0(sp)
    800018e6:	6161                	addi	sp,sp,80
    800018e8:	8082                	ret

00000000800018ea <copyinstr>:
  while(got_null == 0 && max > 0){
    800018ea:	c6c5                	beqz	a3,80001992 <copyinstr+0xa8>
{
    800018ec:	715d                	addi	sp,sp,-80
    800018ee:	e486                	sd	ra,72(sp)
    800018f0:	e0a2                	sd	s0,64(sp)
    800018f2:	fc26                	sd	s1,56(sp)
    800018f4:	f84a                	sd	s2,48(sp)
    800018f6:	f44e                	sd	s3,40(sp)
    800018f8:	f052                	sd	s4,32(sp)
    800018fa:	ec56                	sd	s5,24(sp)
    800018fc:	e85a                	sd	s6,16(sp)
    800018fe:	e45e                	sd	s7,8(sp)
    80001900:	0880                	addi	s0,sp,80
    80001902:	8a2a                	mv	s4,a0
    80001904:	8b2e                	mv	s6,a1
    80001906:	8bb2                	mv	s7,a2
    80001908:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000190a:	7afd                	lui	s5,0xfffff
    n = PGSIZE - (srcva - va0);
    8000190c:	6985                	lui	s3,0x1
    8000190e:	a035                	j	8000193a <copyinstr+0x50>
        *dst = '\0';
    80001910:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001914:	4785                	li	a5,1
  if(got_null){
    80001916:	0017b793          	seqz	a5,a5
    8000191a:	40f00533          	neg	a0,a5
}
    8000191e:	60a6                	ld	ra,72(sp)
    80001920:	6406                	ld	s0,64(sp)
    80001922:	74e2                	ld	s1,56(sp)
    80001924:	7942                	ld	s2,48(sp)
    80001926:	79a2                	ld	s3,40(sp)
    80001928:	7a02                	ld	s4,32(sp)
    8000192a:	6ae2                	ld	s5,24(sp)
    8000192c:	6b42                	ld	s6,16(sp)
    8000192e:	6ba2                	ld	s7,8(sp)
    80001930:	6161                	addi	sp,sp,80
    80001932:	8082                	ret
    srcva = va0 + PGSIZE;
    80001934:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001938:	c8a9                	beqz	s1,8000198a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000193a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000193e:	85ca                	mv	a1,s2
    80001940:	8552                	mv	a0,s4
    80001942:	00000097          	auipc	ra,0x0
    80001946:	e40080e7          	jalr	-448(ra) # 80001782 <walkaddr>
    if(pa0 == 0)
    8000194a:	c131                	beqz	a0,8000198e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000194c:	41790833          	sub	a6,s2,s7
    80001950:	984e                	add	a6,a6,s3
    if(n > max)
    80001952:	0104f363          	bgeu	s1,a6,80001958 <copyinstr+0x6e>
    80001956:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001958:	955e                	add	a0,a0,s7
    8000195a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000195e:	fc080be3          	beqz	a6,80001934 <copyinstr+0x4a>
    80001962:	985a                	add	a6,a6,s6
    80001964:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001966:	41650633          	sub	a2,a0,s6
    8000196a:	14fd                	addi	s1,s1,-1
    8000196c:	9b26                	add	s6,s6,s1
    8000196e:	00f60733          	add	a4,a2,a5
    80001972:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd2e0>
    80001976:	df49                	beqz	a4,80001910 <copyinstr+0x26>
        *dst = *p;
    80001978:	00e78023          	sb	a4,0(a5)
      --max;
    8000197c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001980:	0785                	addi	a5,a5,1
    while(n > 0){
    80001982:	ff0796e3          	bne	a5,a6,8000196e <copyinstr+0x84>
      dst++;
    80001986:	8b42                	mv	s6,a6
    80001988:	b775                	j	80001934 <copyinstr+0x4a>
    8000198a:	4781                	li	a5,0
    8000198c:	b769                	j	80001916 <copyinstr+0x2c>
      return -1;
    8000198e:	557d                	li	a0,-1
    80001990:	b779                	j	8000191e <copyinstr+0x34>
  int got_null = 0;
    80001992:	4781                	li	a5,0
  if(got_null){
    80001994:	0017b793          	seqz	a5,a5
    80001998:	40f00533          	neg	a0,a5
}
    8000199c:	8082                	ret

000000008000199e <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000199e:	7139                	addi	sp,sp,-64
    800019a0:	fc06                	sd	ra,56(sp)
    800019a2:	f822                	sd	s0,48(sp)
    800019a4:	f426                	sd	s1,40(sp)
    800019a6:	f04a                	sd	s2,32(sp)
    800019a8:	ec4e                	sd	s3,24(sp)
    800019aa:	e852                	sd	s4,16(sp)
    800019ac:	e456                	sd	s5,8(sp)
    800019ae:	e05a                	sd	s6,0(sp)
    800019b0:	0080                	addi	s0,sp,64
    800019b2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b4:	0000f497          	auipc	s1,0xf
    800019b8:	58c48493          	addi	s1,s1,1420 # 80010f40 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800019bc:	8b26                	mv	s6,s1
    800019be:	00006a97          	auipc	s5,0x6
    800019c2:	642a8a93          	addi	s5,s5,1602 # 80008000 <etext>
    800019c6:	04000937          	lui	s2,0x4000
    800019ca:	197d                	addi	s2,s2,-1
    800019cc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ce:	00015a17          	auipc	s4,0x15
    800019d2:	f72a0a13          	addi	s4,s4,-142 # 80016940 <tickslock>
    char *pa = kalloc();
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	124080e7          	jalr	292(ra) # 80000afa <kalloc>
    800019de:	862a                	mv	a2,a0
    if(pa == 0)
    800019e0:	c131                	beqz	a0,80001a24 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019e2:	416485b3          	sub	a1,s1,s6
    800019e6:	858d                	srai	a1,a1,0x3
    800019e8:	000ab783          	ld	a5,0(s5)
    800019ec:	02f585b3          	mul	a1,a1,a5
    800019f0:	2585                	addiw	a1,a1,1
    800019f2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019f6:	4719                	li	a4,6
    800019f8:	6685                	lui	a3,0x1
    800019fa:	40b905b3          	sub	a1,s2,a1
    800019fe:	854e                	mv	a0,s3
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	7c4080e7          	jalr	1988(ra) # 800011c4 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a08:	16848493          	addi	s1,s1,360
    80001a0c:	fd4495e3          	bne	s1,s4,800019d6 <proc_mapstacks+0x38>
  }
}
    80001a10:	70e2                	ld	ra,56(sp)
    80001a12:	7442                	ld	s0,48(sp)
    80001a14:	74a2                	ld	s1,40(sp)
    80001a16:	7902                	ld	s2,32(sp)
    80001a18:	69e2                	ld	s3,24(sp)
    80001a1a:	6a42                	ld	s4,16(sp)
    80001a1c:	6aa2                	ld	s5,8(sp)
    80001a1e:	6b02                	ld	s6,0(sp)
    80001a20:	6121                	addi	sp,sp,64
    80001a22:	8082                	ret
      panic("kalloc");
    80001a24:	00006517          	auipc	a0,0x6
    80001a28:	76c50513          	addi	a0,a0,1900 # 80008190 <digits+0x150>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	b18080e7          	jalr	-1256(ra) # 80000544 <panic>

0000000080001a34 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001a34:	7139                	addi	sp,sp,-64
    80001a36:	fc06                	sd	ra,56(sp)
    80001a38:	f822                	sd	s0,48(sp)
    80001a3a:	f426                	sd	s1,40(sp)
    80001a3c:	f04a                	sd	s2,32(sp)
    80001a3e:	ec4e                	sd	s3,24(sp)
    80001a40:	e852                	sd	s4,16(sp)
    80001a42:	e456                	sd	s5,8(sp)
    80001a44:	e05a                	sd	s6,0(sp)
    80001a46:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001a48:	00006597          	auipc	a1,0x6
    80001a4c:	75058593          	addi	a1,a1,1872 # 80008198 <digits+0x158>
    80001a50:	0000f517          	auipc	a0,0xf
    80001a54:	0c050513          	addi	a0,a0,192 # 80010b10 <pid_lock>
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	102080e7          	jalr	258(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001a60:	00006597          	auipc	a1,0x6
    80001a64:	74058593          	addi	a1,a1,1856 # 800081a0 <digits+0x160>
    80001a68:	0000f517          	auipc	a0,0xf
    80001a6c:	0c050513          	addi	a0,a0,192 # 80010b28 <wait_lock>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	0ea080e7          	jalr	234(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a78:	0000f497          	auipc	s1,0xf
    80001a7c:	4c848493          	addi	s1,s1,1224 # 80010f40 <proc>
      initlock(&p->lock, "proc");
    80001a80:	00006b17          	auipc	s6,0x6
    80001a84:	730b0b13          	addi	s6,s6,1840 # 800081b0 <digits+0x170>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001a88:	8aa6                	mv	s5,s1
    80001a8a:	00006a17          	auipc	s4,0x6
    80001a8e:	576a0a13          	addi	s4,s4,1398 # 80008000 <etext>
    80001a92:	04000937          	lui	s2,0x4000
    80001a96:	197d                	addi	s2,s2,-1
    80001a98:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a9a:	00015997          	auipc	s3,0x15
    80001a9e:	ea698993          	addi	s3,s3,-346 # 80016940 <tickslock>
      initlock(&p->lock, "proc");
    80001aa2:	85da                	mv	a1,s6
    80001aa4:	8526                	mv	a0,s1
    80001aa6:	fffff097          	auipc	ra,0xfffff
    80001aaa:	0b4080e7          	jalr	180(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001aae:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001ab2:	415487b3          	sub	a5,s1,s5
    80001ab6:	878d                	srai	a5,a5,0x3
    80001ab8:	000a3703          	ld	a4,0(s4)
    80001abc:	02e787b3          	mul	a5,a5,a4
    80001ac0:	2785                	addiw	a5,a5,1
    80001ac2:	00d7979b          	slliw	a5,a5,0xd
    80001ac6:	40f907b3          	sub	a5,s2,a5
    80001aca:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001acc:	16848493          	addi	s1,s1,360
    80001ad0:	fd3499e3          	bne	s1,s3,80001aa2 <procinit+0x6e>
  }
}
    80001ad4:	70e2                	ld	ra,56(sp)
    80001ad6:	7442                	ld	s0,48(sp)
    80001ad8:	74a2                	ld	s1,40(sp)
    80001ada:	7902                	ld	s2,32(sp)
    80001adc:	69e2                	ld	s3,24(sp)
    80001ade:	6a42                	ld	s4,16(sp)
    80001ae0:	6aa2                	ld	s5,8(sp)
    80001ae2:	6b02                	ld	s6,0(sp)
    80001ae4:	6121                	addi	sp,sp,64
    80001ae6:	8082                	ret

0000000080001ae8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001ae8:	1141                	addi	sp,sp,-16
    80001aea:	e422                	sd	s0,8(sp)
    80001aec:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aee:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001af0:	2501                	sext.w	a0,a0
    80001af2:	6422                	ld	s0,8(sp)
    80001af4:	0141                	addi	sp,sp,16
    80001af6:	8082                	ret

0000000080001af8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001af8:	1141                	addi	sp,sp,-16
    80001afa:	e422                	sd	s0,8(sp)
    80001afc:	0800                	addi	s0,sp,16
    80001afe:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001b00:	2781                	sext.w	a5,a5
    80001b02:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b04:	0000f517          	auipc	a0,0xf
    80001b08:	03c50513          	addi	a0,a0,60 # 80010b40 <cpus>
    80001b0c:	953e                	add	a0,a0,a5
    80001b0e:	6422                	ld	s0,8(sp)
    80001b10:	0141                	addi	sp,sp,16
    80001b12:	8082                	ret

0000000080001b14 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001b14:	1101                	addi	sp,sp,-32
    80001b16:	ec06                	sd	ra,24(sp)
    80001b18:	e822                	sd	s0,16(sp)
    80001b1a:	e426                	sd	s1,8(sp)
    80001b1c:	1000                	addi	s0,sp,32
  push_off();
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	080080e7          	jalr	128(ra) # 80000b9e <push_off>
    80001b26:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b28:	2781                	sext.w	a5,a5
    80001b2a:	079e                	slli	a5,a5,0x7
    80001b2c:	0000f717          	auipc	a4,0xf
    80001b30:	fe470713          	addi	a4,a4,-28 # 80010b10 <pid_lock>
    80001b34:	97ba                	add	a5,a5,a4
    80001b36:	7b84                	ld	s1,48(a5)
  pop_off();
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	106080e7          	jalr	262(ra) # 80000c3e <pop_off>
  return p;
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6105                	addi	sp,sp,32
    80001b4a:	8082                	ret

0000000080001b4c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001b4c:	1141                	addi	sp,sp,-16
    80001b4e:	e406                	sd	ra,8(sp)
    80001b50:	e022                	sd	s0,0(sp)
    80001b52:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b54:	00000097          	auipc	ra,0x0
    80001b58:	fc0080e7          	jalr	-64(ra) # 80001b14 <myproc>
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	142080e7          	jalr	322(ra) # 80000c9e <release>

  if (first) {
    80001b64:	00007797          	auipc	a5,0x7
    80001b68:	c9c7a783          	lw	a5,-868(a5) # 80008800 <first.1692>
    80001b6c:	eb89                	bnez	a5,80001b7e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b6e:	00001097          	auipc	ra,0x1
    80001b72:	cc2080e7          	jalr	-830(ra) # 80002830 <usertrapret>
}
    80001b76:	60a2                	ld	ra,8(sp)
    80001b78:	6402                	ld	s0,0(sp)
    80001b7a:	0141                	addi	sp,sp,16
    80001b7c:	8082                	ret
    first = 0;
    80001b7e:	00007797          	auipc	a5,0x7
    80001b82:	c807a123          	sw	zero,-894(a5) # 80008800 <first.1692>
    fsinit(ROOTDEV);
    80001b86:	4505                	li	a0,1
    80001b88:	00002097          	auipc	ra,0x2
    80001b8c:	a2c080e7          	jalr	-1492(ra) # 800035b4 <fsinit>
    80001b90:	bff9                	j	80001b6e <forkret+0x22>

0000000080001b92 <allocpid>:
{
    80001b92:	1101                	addi	sp,sp,-32
    80001b94:	ec06                	sd	ra,24(sp)
    80001b96:	e822                	sd	s0,16(sp)
    80001b98:	e426                	sd	s1,8(sp)
    80001b9a:	e04a                	sd	s2,0(sp)
    80001b9c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b9e:	0000f917          	auipc	s2,0xf
    80001ba2:	f7290913          	addi	s2,s2,-142 # 80010b10 <pid_lock>
    80001ba6:	854a                	mv	a0,s2
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	042080e7          	jalr	66(ra) # 80000bea <acquire>
  pid = nextpid;
    80001bb0:	00007797          	auipc	a5,0x7
    80001bb4:	c5478793          	addi	a5,a5,-940 # 80008804 <nextpid>
    80001bb8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bba:	0014871b          	addiw	a4,s1,1
    80001bbe:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bc0:	854a                	mv	a0,s2
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	0dc080e7          	jalr	220(ra) # 80000c9e <release>
}
    80001bca:	8526                	mv	a0,s1
    80001bcc:	60e2                	ld	ra,24(sp)
    80001bce:	6442                	ld	s0,16(sp)
    80001bd0:	64a2                	ld	s1,8(sp)
    80001bd2:	6902                	ld	s2,0(sp)
    80001bd4:	6105                	addi	sp,sp,32
    80001bd6:	8082                	ret

0000000080001bd8 <proc_pagetable>:
{
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	addi	s0,sp,32
    80001be4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001be6:	fffff097          	auipc	ra,0xfffff
    80001bea:	7aa080e7          	jalr	1962(ra) # 80001390 <uvmcreate>
    80001bee:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bf0:	c121                	beqz	a0,80001c30 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bf2:	4729                	li	a4,10
    80001bf4:	00005697          	auipc	a3,0x5
    80001bf8:	40c68693          	addi	a3,a3,1036 # 80007000 <_trampoline>
    80001bfc:	6605                	lui	a2,0x1
    80001bfe:	040005b7          	lui	a1,0x4000
    80001c02:	15fd                	addi	a1,a1,-1
    80001c04:	05b2                	slli	a1,a1,0xc
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	52a080e7          	jalr	1322(ra) # 80001130 <mappages>
    80001c0e:	02054863          	bltz	a0,80001c3e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c12:	4719                	li	a4,6
    80001c14:	05893683          	ld	a3,88(s2)
    80001c18:	6605                	lui	a2,0x1
    80001c1a:	020005b7          	lui	a1,0x2000
    80001c1e:	15fd                	addi	a1,a1,-1
    80001c20:	05b6                	slli	a1,a1,0xd
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	50c080e7          	jalr	1292(ra) # 80001130 <mappages>
    80001c2c:	02054163          	bltz	a0,80001c4e <proc_pagetable+0x76>
}
    80001c30:	8526                	mv	a0,s1
    80001c32:	60e2                	ld	ra,24(sp)
    80001c34:	6442                	ld	s0,16(sp)
    80001c36:	64a2                	ld	s1,8(sp)
    80001c38:	6902                	ld	s2,0(sp)
    80001c3a:	6105                	addi	sp,sp,32
    80001c3c:	8082                	ret
    uvmfree(pagetable, 0);
    80001c3e:	4581                	li	a1,0
    80001c40:	8526                	mv	a0,s1
    80001c42:	00000097          	auipc	ra,0x0
    80001c46:	952080e7          	jalr	-1710(ra) # 80001594 <uvmfree>
    return 0;
    80001c4a:	4481                	li	s1,0
    80001c4c:	b7d5                	j	80001c30 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c4e:	4681                	li	a3,0
    80001c50:	4605                	li	a2,1
    80001c52:	040005b7          	lui	a1,0x4000
    80001c56:	15fd                	addi	a1,a1,-1
    80001c58:	05b2                	slli	a1,a1,0xc
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	68e080e7          	jalr	1678(ra) # 800012ea <uvmunmap>
    uvmfree(pagetable, 0);
    80001c64:	4581                	li	a1,0
    80001c66:	8526                	mv	a0,s1
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	92c080e7          	jalr	-1748(ra) # 80001594 <uvmfree>
    return 0;
    80001c70:	4481                	li	s1,0
    80001c72:	bf7d                	j	80001c30 <proc_pagetable+0x58>

0000000080001c74 <proc_freepagetable>:
{
    80001c74:	1101                	addi	sp,sp,-32
    80001c76:	ec06                	sd	ra,24(sp)
    80001c78:	e822                	sd	s0,16(sp)
    80001c7a:	e426                	sd	s1,8(sp)
    80001c7c:	e04a                	sd	s2,0(sp)
    80001c7e:	1000                	addi	s0,sp,32
    80001c80:	84aa                	mv	s1,a0
    80001c82:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c84:	4681                	li	a3,0
    80001c86:	4605                	li	a2,1
    80001c88:	040005b7          	lui	a1,0x4000
    80001c8c:	15fd                	addi	a1,a1,-1
    80001c8e:	05b2                	slli	a1,a1,0xc
    80001c90:	fffff097          	auipc	ra,0xfffff
    80001c94:	65a080e7          	jalr	1626(ra) # 800012ea <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c98:	4681                	li	a3,0
    80001c9a:	4605                	li	a2,1
    80001c9c:	020005b7          	lui	a1,0x2000
    80001ca0:	15fd                	addi	a1,a1,-1
    80001ca2:	05b6                	slli	a1,a1,0xd
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	644080e7          	jalr	1604(ra) # 800012ea <uvmunmap>
  uvmfree(pagetable, sz);
    80001cae:	85ca                	mv	a1,s2
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	00000097          	auipc	ra,0x0
    80001cb6:	8e2080e7          	jalr	-1822(ra) # 80001594 <uvmfree>
}
    80001cba:	60e2                	ld	ra,24(sp)
    80001cbc:	6442                	ld	s0,16(sp)
    80001cbe:	64a2                	ld	s1,8(sp)
    80001cc0:	6902                	ld	s2,0(sp)
    80001cc2:	6105                	addi	sp,sp,32
    80001cc4:	8082                	ret

0000000080001cc6 <freeproc>:
{
    80001cc6:	1101                	addi	sp,sp,-32
    80001cc8:	ec06                	sd	ra,24(sp)
    80001cca:	e822                	sd	s0,16(sp)
    80001ccc:	e426                	sd	s1,8(sp)
    80001cce:	1000                	addi	s0,sp,32
    80001cd0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cd2:	6d28                	ld	a0,88(a0)
    80001cd4:	c509                	beqz	a0,80001cde <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	d28080e7          	jalr	-728(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001cde:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001ce2:	68a8                	ld	a0,80(s1)
    80001ce4:	c511                	beqz	a0,80001cf0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ce6:	64ac                	ld	a1,72(s1)
    80001ce8:	00000097          	auipc	ra,0x0
    80001cec:	f8c080e7          	jalr	-116(ra) # 80001c74 <proc_freepagetable>
  p->pagetable = 0;
    80001cf0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cf4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cf8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cfc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001d00:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d04:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d08:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d0c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d10:	0004ac23          	sw	zero,24(s1)
}
    80001d14:	60e2                	ld	ra,24(sp)
    80001d16:	6442                	ld	s0,16(sp)
    80001d18:	64a2                	ld	s1,8(sp)
    80001d1a:	6105                	addi	sp,sp,32
    80001d1c:	8082                	ret

0000000080001d1e <allocproc>:
{
    80001d1e:	1101                	addi	sp,sp,-32
    80001d20:	ec06                	sd	ra,24(sp)
    80001d22:	e822                	sd	s0,16(sp)
    80001d24:	e426                	sd	s1,8(sp)
    80001d26:	e04a                	sd	s2,0(sp)
    80001d28:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d2a:	0000f497          	auipc	s1,0xf
    80001d2e:	21648493          	addi	s1,s1,534 # 80010f40 <proc>
    80001d32:	00015917          	auipc	s2,0x15
    80001d36:	c0e90913          	addi	s2,s2,-1010 # 80016940 <tickslock>
    acquire(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	eae080e7          	jalr	-338(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001d44:	4c9c                	lw	a5,24(s1)
    80001d46:	cf81                	beqz	a5,80001d5e <allocproc+0x40>
      release(&p->lock);
    80001d48:	8526                	mv	a0,s1
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	f54080e7          	jalr	-172(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d52:	16848493          	addi	s1,s1,360
    80001d56:	ff2492e3          	bne	s1,s2,80001d3a <allocproc+0x1c>
  return 0;
    80001d5a:	4481                	li	s1,0
    80001d5c:	a889                	j	80001dae <allocproc+0x90>
  p->pid = allocpid();
    80001d5e:	00000097          	auipc	ra,0x0
    80001d62:	e34080e7          	jalr	-460(ra) # 80001b92 <allocpid>
    80001d66:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d68:	4785                	li	a5,1
    80001d6a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	d8e080e7          	jalr	-626(ra) # 80000afa <kalloc>
    80001d74:	892a                	mv	s2,a0
    80001d76:	eca8                	sd	a0,88(s1)
    80001d78:	c131                	beqz	a0,80001dbc <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	e5c080e7          	jalr	-420(ra) # 80001bd8 <proc_pagetable>
    80001d84:	892a                	mv	s2,a0
    80001d86:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d88:	c531                	beqz	a0,80001dd4 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d8a:	07000613          	li	a2,112
    80001d8e:	4581                	li	a1,0
    80001d90:	06048513          	addi	a0,s1,96
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	f52080e7          	jalr	-174(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001d9c:	00000797          	auipc	a5,0x0
    80001da0:	db078793          	addi	a5,a5,-592 # 80001b4c <forkret>
    80001da4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001da6:	60bc                	ld	a5,64(s1)
    80001da8:	6705                	lui	a4,0x1
    80001daa:	97ba                	add	a5,a5,a4
    80001dac:	f4bc                	sd	a5,104(s1)
}
    80001dae:	8526                	mv	a0,s1
    80001db0:	60e2                	ld	ra,24(sp)
    80001db2:	6442                	ld	s0,16(sp)
    80001db4:	64a2                	ld	s1,8(sp)
    80001db6:	6902                	ld	s2,0(sp)
    80001db8:	6105                	addi	sp,sp,32
    80001dba:	8082                	ret
    freeproc(p);
    80001dbc:	8526                	mv	a0,s1
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	f08080e7          	jalr	-248(ra) # 80001cc6 <freeproc>
    release(&p->lock);
    80001dc6:	8526                	mv	a0,s1
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	ed6080e7          	jalr	-298(ra) # 80000c9e <release>
    return 0;
    80001dd0:	84ca                	mv	s1,s2
    80001dd2:	bff1                	j	80001dae <allocproc+0x90>
    freeproc(p);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	ef0080e7          	jalr	-272(ra) # 80001cc6 <freeproc>
    release(&p->lock);
    80001dde:	8526                	mv	a0,s1
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	ebe080e7          	jalr	-322(ra) # 80000c9e <release>
    return 0;
    80001de8:	84ca                	mv	s1,s2
    80001dea:	b7d1                	j	80001dae <allocproc+0x90>

0000000080001dec <userinit>:
{
    80001dec:	1101                	addi	sp,sp,-32
    80001dee:	ec06                	sd	ra,24(sp)
    80001df0:	e822                	sd	s0,16(sp)
    80001df2:	e426                	sd	s1,8(sp)
    80001df4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	f28080e7          	jalr	-216(ra) # 80001d1e <allocproc>
    80001dfe:	84aa                	mv	s1,a0
  initproc = p;
    80001e00:	00007797          	auipc	a5,0x7
    80001e04:	a8a7bc23          	sd	a0,-1384(a5) # 80008898 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e08:	03400613          	li	a2,52
    80001e0c:	00007597          	auipc	a1,0x7
    80001e10:	a0458593          	addi	a1,a1,-1532 # 80008810 <initcode>
    80001e14:	6928                	ld	a0,80(a0)
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	5a8080e7          	jalr	1448(ra) # 800013be <uvmfirst>
  p->sz = PGSIZE;
    80001e1e:	6785                	lui	a5,0x1
    80001e20:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e22:	6cb8                	ld	a4,88(s1)
    80001e24:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e28:	6cb8                	ld	a4,88(s1)
    80001e2a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e2c:	4641                	li	a2,16
    80001e2e:	00006597          	auipc	a1,0x6
    80001e32:	38a58593          	addi	a1,a1,906 # 800081b8 <digits+0x178>
    80001e36:	15848513          	addi	a0,s1,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	ffe080e7          	jalr	-2(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001e42:	00006517          	auipc	a0,0x6
    80001e46:	38650513          	addi	a0,a0,902 # 800081c8 <digits+0x188>
    80001e4a:	00002097          	auipc	ra,0x2
    80001e4e:	18c080e7          	jalr	396(ra) # 80003fd6 <namei>
    80001e52:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e56:	478d                	li	a5,3
    80001e58:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e5a:	8526                	mv	a0,s1
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e42080e7          	jalr	-446(ra) # 80000c9e <release>
}
    80001e64:	60e2                	ld	ra,24(sp)
    80001e66:	6442                	ld	s0,16(sp)
    80001e68:	64a2                	ld	s1,8(sp)
    80001e6a:	6105                	addi	sp,sp,32
    80001e6c:	8082                	ret

0000000080001e6e <growproc>:
{
    80001e6e:	1101                	addi	sp,sp,-32
    80001e70:	ec06                	sd	ra,24(sp)
    80001e72:	e822                	sd	s0,16(sp)
    80001e74:	e426                	sd	s1,8(sp)
    80001e76:	e04a                	sd	s2,0(sp)
    80001e78:	1000                	addi	s0,sp,32
    80001e7a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	c98080e7          	jalr	-872(ra) # 80001b14 <myproc>
    80001e84:	84aa                	mv	s1,a0
  sz = p->sz;
    80001e86:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001e88:	01204c63          	bgtz	s2,80001ea0 <growproc+0x32>
  } else if(n < 0){
    80001e8c:	02094663          	bltz	s2,80001eb8 <growproc+0x4a>
  p->sz = sz;
    80001e90:	e4ac                	sd	a1,72(s1)
  return 0;
    80001e92:	4501                	li	a0,0
}
    80001e94:	60e2                	ld	ra,24(sp)
    80001e96:	6442                	ld	s0,16(sp)
    80001e98:	64a2                	ld	s1,8(sp)
    80001e9a:	6902                	ld	s2,0(sp)
    80001e9c:	6105                	addi	sp,sp,32
    80001e9e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001ea0:	4691                	li	a3,4
    80001ea2:	00b90633          	add	a2,s2,a1
    80001ea6:	6928                	ld	a0,80(a0)
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	5d0080e7          	jalr	1488(ra) # 80001478 <uvmalloc>
    80001eb0:	85aa                	mv	a1,a0
    80001eb2:	fd79                	bnez	a0,80001e90 <growproc+0x22>
      return -1;
    80001eb4:	557d                	li	a0,-1
    80001eb6:	bff9                	j	80001e94 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001eb8:	00b90633          	add	a2,s2,a1
    80001ebc:	6928                	ld	a0,80(a0)
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	572080e7          	jalr	1394(ra) # 80001430 <uvmdealloc>
    80001ec6:	85aa                	mv	a1,a0
    80001ec8:	b7e1                	j	80001e90 <growproc+0x22>

0000000080001eca <handle_page_fault>:
  if (addr >= p->sz) return -1;
    80001eca:	653c                	ld	a5,72(a0)
    80001ecc:	06f5f163          	bgeu	a1,a5,80001f2e <handle_page_fault+0x64>
int handle_page_fault(struct proc* p, uint64 addr) {
    80001ed0:	7179                	addi	sp,sp,-48
    80001ed2:	f406                	sd	ra,40(sp)
    80001ed4:	f022                	sd	s0,32(sp)
    80001ed6:	ec26                	sd	s1,24(sp)
    80001ed8:	e84a                	sd	s2,16(sp)
    80001eda:	e44e                	sd	s3,8(sp)
    80001edc:	1800                	addi	s0,sp,48
    80001ede:	89aa                	mv	s3,a0
  uint64 page_addr = PGROUNDDOWN(addr);
    80001ee0:	74fd                	lui	s1,0xfffff
    80001ee2:	8ced                	and	s1,s1,a1
  mem = kalloc();
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	c16080e7          	jalr	-1002(ra) # 80000afa <kalloc>
    80001eec:	892a                	mv	s2,a0
  if (mem == 0) return -1;
    80001eee:	c131                	beqz	a0,80001f32 <handle_page_fault+0x68>
  memset(mem, 0, PGSIZE);
    80001ef0:	6605                	lui	a2,0x1
    80001ef2:	4581                	li	a1,0
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	df2080e7          	jalr	-526(ra) # 80000ce6 <memset>
  if(mappages(p->pagetable, page_addr, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001efc:	4779                	li	a4,30
    80001efe:	86ca                	mv	a3,s2
    80001f00:	6605                	lui	a2,0x1
    80001f02:	85a6                	mv	a1,s1
    80001f04:	0509b503          	ld	a0,80(s3)
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	228080e7          	jalr	552(ra) # 80001130 <mappages>
    80001f10:	e901                	bnez	a0,80001f20 <handle_page_fault+0x56>
}
    80001f12:	70a2                	ld	ra,40(sp)
    80001f14:	7402                	ld	s0,32(sp)
    80001f16:	64e2                	ld	s1,24(sp)
    80001f18:	6942                	ld	s2,16(sp)
    80001f1a:	69a2                	ld	s3,8(sp)
    80001f1c:	6145                	addi	sp,sp,48
    80001f1e:	8082                	ret
    kfree(mem);
    80001f20:	854a                	mv	a0,s2
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	adc080e7          	jalr	-1316(ra) # 800009fe <kfree>
    return -1;
    80001f2a:	557d                	li	a0,-1
    80001f2c:	b7dd                	j	80001f12 <handle_page_fault+0x48>
  if (addr >= p->sz) return -1;
    80001f2e:	557d                	li	a0,-1
}
    80001f30:	8082                	ret
  if (mem == 0) return -1;
    80001f32:	557d                	li	a0,-1
    80001f34:	bff9                	j	80001f12 <handle_page_fault+0x48>

0000000080001f36 <fork>:
{
    80001f36:	7179                	addi	sp,sp,-48
    80001f38:	f406                	sd	ra,40(sp)
    80001f3a:	f022                	sd	s0,32(sp)
    80001f3c:	ec26                	sd	s1,24(sp)
    80001f3e:	e84a                	sd	s2,16(sp)
    80001f40:	e44e                	sd	s3,8(sp)
    80001f42:	e052                	sd	s4,0(sp)
    80001f44:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	bce080e7          	jalr	-1074(ra) # 80001b14 <myproc>
    80001f4e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	dce080e7          	jalr	-562(ra) # 80001d1e <allocproc>
    80001f58:	10050b63          	beqz	a0,8000206e <fork+0x138>
    80001f5c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f5e:	04893603          	ld	a2,72(s2)
    80001f62:	692c                	ld	a1,80(a0)
    80001f64:	05093503          	ld	a0,80(s2)
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	664080e7          	jalr	1636(ra) # 800015cc <uvmcopy>
    80001f70:	04054663          	bltz	a0,80001fbc <fork+0x86>
  np->sz = p->sz;
    80001f74:	04893783          	ld	a5,72(s2)
    80001f78:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f7c:	05893683          	ld	a3,88(s2)
    80001f80:	87b6                	mv	a5,a3
    80001f82:	0589b703          	ld	a4,88(s3)
    80001f86:	12068693          	addi	a3,a3,288
    80001f8a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f8e:	6788                	ld	a0,8(a5)
    80001f90:	6b8c                	ld	a1,16(a5)
    80001f92:	6f90                	ld	a2,24(a5)
    80001f94:	01073023          	sd	a6,0(a4)
    80001f98:	e708                	sd	a0,8(a4)
    80001f9a:	eb0c                	sd	a1,16(a4)
    80001f9c:	ef10                	sd	a2,24(a4)
    80001f9e:	02078793          	addi	a5,a5,32
    80001fa2:	02070713          	addi	a4,a4,32
    80001fa6:	fed792e3          	bne	a5,a3,80001f8a <fork+0x54>
  np->trapframe->a0 = 0;
    80001faa:	0589b783          	ld	a5,88(s3)
    80001fae:	0607b823          	sd	zero,112(a5)
    80001fb2:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001fb6:	15000a13          	li	s4,336
    80001fba:	a03d                	j	80001fe8 <fork+0xb2>
    freeproc(np);
    80001fbc:	854e                	mv	a0,s3
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	d08080e7          	jalr	-760(ra) # 80001cc6 <freeproc>
    release(&np->lock);
    80001fc6:	854e                	mv	a0,s3
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	cd6080e7          	jalr	-810(ra) # 80000c9e <release>
    return -1;
    80001fd0:	5a7d                	li	s4,-1
    80001fd2:	a069                	j	8000205c <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fd4:	00002097          	auipc	ra,0x2
    80001fd8:	698080e7          	jalr	1688(ra) # 8000466c <filedup>
    80001fdc:	009987b3          	add	a5,s3,s1
    80001fe0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001fe2:	04a1                	addi	s1,s1,8
    80001fe4:	01448763          	beq	s1,s4,80001ff2 <fork+0xbc>
    if(p->ofile[i])
    80001fe8:	009907b3          	add	a5,s2,s1
    80001fec:	6388                	ld	a0,0(a5)
    80001fee:	f17d                	bnez	a0,80001fd4 <fork+0x9e>
    80001ff0:	bfcd                	j	80001fe2 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ff2:	15093503          	ld	a0,336(s2)
    80001ff6:	00001097          	auipc	ra,0x1
    80001ffa:	7fc080e7          	jalr	2044(ra) # 800037f2 <idup>
    80001ffe:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002002:	4641                	li	a2,16
    80002004:	15890593          	addi	a1,s2,344
    80002008:	15898513          	addi	a0,s3,344
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	e2c080e7          	jalr	-468(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80002014:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002018:	854e                	mv	a0,s3
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	c84080e7          	jalr	-892(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80002022:	0000f497          	auipc	s1,0xf
    80002026:	b0648493          	addi	s1,s1,-1274 # 80010b28 <wait_lock>
    8000202a:	8526                	mv	a0,s1
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	bbe080e7          	jalr	-1090(ra) # 80000bea <acquire>
  np->parent = p;
    80002034:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80002038:	8526                	mv	a0,s1
    8000203a:	fffff097          	auipc	ra,0xfffff
    8000203e:	c64080e7          	jalr	-924(ra) # 80000c9e <release>
  acquire(&np->lock);
    80002042:	854e                	mv	a0,s3
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	ba6080e7          	jalr	-1114(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    8000204c:	478d                	li	a5,3
    8000204e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002052:	854e                	mv	a0,s3
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	c4a080e7          	jalr	-950(ra) # 80000c9e <release>
}
    8000205c:	8552                	mv	a0,s4
    8000205e:	70a2                	ld	ra,40(sp)
    80002060:	7402                	ld	s0,32(sp)
    80002062:	64e2                	ld	s1,24(sp)
    80002064:	6942                	ld	s2,16(sp)
    80002066:	69a2                	ld	s3,8(sp)
    80002068:	6a02                	ld	s4,0(sp)
    8000206a:	6145                	addi	sp,sp,48
    8000206c:	8082                	ret
    return -1;
    8000206e:	5a7d                	li	s4,-1
    80002070:	b7f5                	j	8000205c <fork+0x126>

0000000080002072 <scheduler>:
{
    80002072:	7139                	addi	sp,sp,-64
    80002074:	fc06                	sd	ra,56(sp)
    80002076:	f822                	sd	s0,48(sp)
    80002078:	f426                	sd	s1,40(sp)
    8000207a:	f04a                	sd	s2,32(sp)
    8000207c:	ec4e                	sd	s3,24(sp)
    8000207e:	e852                	sd	s4,16(sp)
    80002080:	e456                	sd	s5,8(sp)
    80002082:	e05a                	sd	s6,0(sp)
    80002084:	0080                	addi	s0,sp,64
    80002086:	8792                	mv	a5,tp
  int id = r_tp();
    80002088:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000208a:	00779a93          	slli	s5,a5,0x7
    8000208e:	0000f717          	auipc	a4,0xf
    80002092:	a8270713          	addi	a4,a4,-1406 # 80010b10 <pid_lock>
    80002096:	9756                	add	a4,a4,s5
    80002098:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000209c:	0000f717          	auipc	a4,0xf
    800020a0:	aac70713          	addi	a4,a4,-1364 # 80010b48 <cpus+0x8>
    800020a4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800020a6:	498d                	li	s3,3
        p->state = RUNNING;
    800020a8:	4b11                	li	s6,4
        c->proc = p;
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	0000fa17          	auipc	s4,0xf
    800020b0:	a64a0a13          	addi	s4,s4,-1436 # 80010b10 <pid_lock>
    800020b4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020b6:	00015917          	auipc	s2,0x15
    800020ba:	88a90913          	addi	s2,s2,-1910 # 80016940 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020be:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020c2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020c6:	10079073          	csrw	sstatus,a5
    800020ca:	0000f497          	auipc	s1,0xf
    800020ce:	e7648493          	addi	s1,s1,-394 # 80010f40 <proc>
    800020d2:	a03d                	j	80002100 <scheduler+0x8e>
        p->state = RUNNING;
    800020d4:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    800020d8:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    800020dc:	06048593          	addi	a1,s1,96
    800020e0:	8556                	mv	a0,s5
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	6a4080e7          	jalr	1700(ra) # 80002786 <swtch>
        c->proc = 0;
    800020ea:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	bae080e7          	jalr	-1106(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020f8:	16848493          	addi	s1,s1,360
    800020fc:	fd2481e3          	beq	s1,s2,800020be <scheduler+0x4c>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ae8080e7          	jalr	-1304(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	ff3791e3          	bne	a5,s3,800020ee <scheduler+0x7c>
    80002110:	b7d1                	j	800020d4 <scheduler+0x62>

0000000080002112 <sched>:
{
    80002112:	7179                	addi	sp,sp,-48
    80002114:	f406                	sd	ra,40(sp)
    80002116:	f022                	sd	s0,32(sp)
    80002118:	ec26                	sd	s1,24(sp)
    8000211a:	e84a                	sd	s2,16(sp)
    8000211c:	e44e                	sd	s3,8(sp)
    8000211e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002120:	00000097          	auipc	ra,0x0
    80002124:	9f4080e7          	jalr	-1548(ra) # 80001b14 <myproc>
    80002128:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	a46080e7          	jalr	-1466(ra) # 80000b70 <holding>
    80002132:	c93d                	beqz	a0,800021a8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002134:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002136:	2781                	sext.w	a5,a5
    80002138:	079e                	slli	a5,a5,0x7
    8000213a:	0000f717          	auipc	a4,0xf
    8000213e:	9d670713          	addi	a4,a4,-1578 # 80010b10 <pid_lock>
    80002142:	97ba                	add	a5,a5,a4
    80002144:	0a87a703          	lw	a4,168(a5)
    80002148:	4785                	li	a5,1
    8000214a:	06f71763          	bne	a4,a5,800021b8 <sched+0xa6>
  if(p->state == RUNNING)
    8000214e:	4c98                	lw	a4,24(s1)
    80002150:	4791                	li	a5,4
    80002152:	06f70b63          	beq	a4,a5,800021c8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002156:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000215a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000215c:	efb5                	bnez	a5,800021d8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000215e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002160:	0000f917          	auipc	s2,0xf
    80002164:	9b090913          	addi	s2,s2,-1616 # 80010b10 <pid_lock>
    80002168:	2781                	sext.w	a5,a5
    8000216a:	079e                	slli	a5,a5,0x7
    8000216c:	97ca                	add	a5,a5,s2
    8000216e:	0ac7a983          	lw	s3,172(a5)
    80002172:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002174:	2781                	sext.w	a5,a5
    80002176:	079e                	slli	a5,a5,0x7
    80002178:	0000f597          	auipc	a1,0xf
    8000217c:	9d058593          	addi	a1,a1,-1584 # 80010b48 <cpus+0x8>
    80002180:	95be                	add	a1,a1,a5
    80002182:	06048513          	addi	a0,s1,96
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	600080e7          	jalr	1536(ra) # 80002786 <swtch>
    8000218e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002190:	2781                	sext.w	a5,a5
    80002192:	079e                	slli	a5,a5,0x7
    80002194:	97ca                	add	a5,a5,s2
    80002196:	0b37a623          	sw	s3,172(a5)
}
    8000219a:	70a2                	ld	ra,40(sp)
    8000219c:	7402                	ld	s0,32(sp)
    8000219e:	64e2                	ld	s1,24(sp)
    800021a0:	6942                	ld	s2,16(sp)
    800021a2:	69a2                	ld	s3,8(sp)
    800021a4:	6145                	addi	sp,sp,48
    800021a6:	8082                	ret
    panic("sched p->lock");
    800021a8:	00006517          	auipc	a0,0x6
    800021ac:	02850513          	addi	a0,a0,40 # 800081d0 <digits+0x190>
    800021b0:	ffffe097          	auipc	ra,0xffffe
    800021b4:	394080e7          	jalr	916(ra) # 80000544 <panic>
    panic("sched locks");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	02850513          	addi	a0,a0,40 # 800081e0 <digits+0x1a0>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	384080e7          	jalr	900(ra) # 80000544 <panic>
    panic("sched running");
    800021c8:	00006517          	auipc	a0,0x6
    800021cc:	02850513          	addi	a0,a0,40 # 800081f0 <digits+0x1b0>
    800021d0:	ffffe097          	auipc	ra,0xffffe
    800021d4:	374080e7          	jalr	884(ra) # 80000544 <panic>
    panic("sched interruptible");
    800021d8:	00006517          	auipc	a0,0x6
    800021dc:	02850513          	addi	a0,a0,40 # 80008200 <digits+0x1c0>
    800021e0:	ffffe097          	auipc	ra,0xffffe
    800021e4:	364080e7          	jalr	868(ra) # 80000544 <panic>

00000000800021e8 <yield>:
{
    800021e8:	1101                	addi	sp,sp,-32
    800021ea:	ec06                	sd	ra,24(sp)
    800021ec:	e822                	sd	s0,16(sp)
    800021ee:	e426                	sd	s1,8(sp)
    800021f0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	922080e7          	jalr	-1758(ra) # 80001b14 <myproc>
    800021fa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	9ee080e7          	jalr	-1554(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    80002204:	478d                	li	a5,3
    80002206:	cc9c                	sw	a5,24(s1)
  sched();
    80002208:	00000097          	auipc	ra,0x0
    8000220c:	f0a080e7          	jalr	-246(ra) # 80002112 <sched>
  release(&p->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a8c080e7          	jalr	-1396(ra) # 80000c9e <release>
}
    8000221a:	60e2                	ld	ra,24(sp)
    8000221c:	6442                	ld	s0,16(sp)
    8000221e:	64a2                	ld	s1,8(sp)
    80002220:	6105                	addi	sp,sp,32
    80002222:	8082                	ret

0000000080002224 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002224:	7179                	addi	sp,sp,-48
    80002226:	f406                	sd	ra,40(sp)
    80002228:	f022                	sd	s0,32(sp)
    8000222a:	ec26                	sd	s1,24(sp)
    8000222c:	e84a                	sd	s2,16(sp)
    8000222e:	e44e                	sd	s3,8(sp)
    80002230:	1800                	addi	s0,sp,48
    80002232:	89aa                	mv	s3,a0
    80002234:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	8de080e7          	jalr	-1826(ra) # 80001b14 <myproc>
    8000223e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9aa080e7          	jalr	-1622(ra) # 80000bea <acquire>
  release(lk);
    80002248:	854a                	mv	a0,s2
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	a54080e7          	jalr	-1452(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002252:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002256:	4789                	li	a5,2
    80002258:	cc9c                	sw	a5,24(s1)

  sched();
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	eb8080e7          	jalr	-328(ra) # 80002112 <sched>

  // Tidy up.
  p->chan = 0;
    80002262:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002266:	8526                	mv	a0,s1
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	a36080e7          	jalr	-1482(ra) # 80000c9e <release>
  acquire(lk);
    80002270:	854a                	mv	a0,s2
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	978080e7          	jalr	-1672(ra) # 80000bea <acquire>
}
    8000227a:	70a2                	ld	ra,40(sp)
    8000227c:	7402                	ld	s0,32(sp)
    8000227e:	64e2                	ld	s1,24(sp)
    80002280:	6942                	ld	s2,16(sp)
    80002282:	69a2                	ld	s3,8(sp)
    80002284:	6145                	addi	sp,sp,48
    80002286:	8082                	ret

0000000080002288 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002288:	7139                	addi	sp,sp,-64
    8000228a:	fc06                	sd	ra,56(sp)
    8000228c:	f822                	sd	s0,48(sp)
    8000228e:	f426                	sd	s1,40(sp)
    80002290:	f04a                	sd	s2,32(sp)
    80002292:	ec4e                	sd	s3,24(sp)
    80002294:	e852                	sd	s4,16(sp)
    80002296:	e456                	sd	s5,8(sp)
    80002298:	0080                	addi	s0,sp,64
    8000229a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000229c:	0000f497          	auipc	s1,0xf
    800022a0:	ca448493          	addi	s1,s1,-860 # 80010f40 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022a4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022a6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022a8:	00014917          	auipc	s2,0x14
    800022ac:	69890913          	addi	s2,s2,1688 # 80016940 <tickslock>
    800022b0:	a821                	j	800022c8 <wakeup+0x40>
        p->state = RUNNABLE;
    800022b2:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9e6080e7          	jalr	-1562(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022c0:	16848493          	addi	s1,s1,360
    800022c4:	03248463          	beq	s1,s2,800022ec <wakeup+0x64>
    if(p != myproc()){
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	84c080e7          	jalr	-1972(ra) # 80001b14 <myproc>
    800022d0:	fea488e3          	beq	s1,a0,800022c0 <wakeup+0x38>
      acquire(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	914080e7          	jalr	-1772(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800022de:	4c9c                	lw	a5,24(s1)
    800022e0:	fd379be3          	bne	a5,s3,800022b6 <wakeup+0x2e>
    800022e4:	709c                	ld	a5,32(s1)
    800022e6:	fd4798e3          	bne	a5,s4,800022b6 <wakeup+0x2e>
    800022ea:	b7e1                	j	800022b2 <wakeup+0x2a>
    }
  }
}
    800022ec:	70e2                	ld	ra,56(sp)
    800022ee:	7442                	ld	s0,48(sp)
    800022f0:	74a2                	ld	s1,40(sp)
    800022f2:	7902                	ld	s2,32(sp)
    800022f4:	69e2                	ld	s3,24(sp)
    800022f6:	6a42                	ld	s4,16(sp)
    800022f8:	6aa2                	ld	s5,8(sp)
    800022fa:	6121                	addi	sp,sp,64
    800022fc:	8082                	ret

00000000800022fe <reparent>:
{
    800022fe:	7179                	addi	sp,sp,-48
    80002300:	f406                	sd	ra,40(sp)
    80002302:	f022                	sd	s0,32(sp)
    80002304:	ec26                	sd	s1,24(sp)
    80002306:	e84a                	sd	s2,16(sp)
    80002308:	e44e                	sd	s3,8(sp)
    8000230a:	e052                	sd	s4,0(sp)
    8000230c:	1800                	addi	s0,sp,48
    8000230e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002310:	0000f497          	auipc	s1,0xf
    80002314:	c3048493          	addi	s1,s1,-976 # 80010f40 <proc>
      pp->parent = initproc;
    80002318:	00006a17          	auipc	s4,0x6
    8000231c:	580a0a13          	addi	s4,s4,1408 # 80008898 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002320:	00014997          	auipc	s3,0x14
    80002324:	62098993          	addi	s3,s3,1568 # 80016940 <tickslock>
    80002328:	a029                	j	80002332 <reparent+0x34>
    8000232a:	16848493          	addi	s1,s1,360
    8000232e:	01348d63          	beq	s1,s3,80002348 <reparent+0x4a>
    if(pp->parent == p){
    80002332:	7c9c                	ld	a5,56(s1)
    80002334:	ff279be3          	bne	a5,s2,8000232a <reparent+0x2c>
      pp->parent = initproc;
    80002338:	000a3503          	ld	a0,0(s4)
    8000233c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	f4a080e7          	jalr	-182(ra) # 80002288 <wakeup>
    80002346:	b7d5                	j	8000232a <reparent+0x2c>
}
    80002348:	70a2                	ld	ra,40(sp)
    8000234a:	7402                	ld	s0,32(sp)
    8000234c:	64e2                	ld	s1,24(sp)
    8000234e:	6942                	ld	s2,16(sp)
    80002350:	69a2                	ld	s3,8(sp)
    80002352:	6a02                	ld	s4,0(sp)
    80002354:	6145                	addi	sp,sp,48
    80002356:	8082                	ret

0000000080002358 <exit>:
{
    80002358:	7179                	addi	sp,sp,-48
    8000235a:	f406                	sd	ra,40(sp)
    8000235c:	f022                	sd	s0,32(sp)
    8000235e:	ec26                	sd	s1,24(sp)
    80002360:	e84a                	sd	s2,16(sp)
    80002362:	e44e                	sd	s3,8(sp)
    80002364:	e052                	sd	s4,0(sp)
    80002366:	1800                	addi	s0,sp,48
    80002368:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	7aa080e7          	jalr	1962(ra) # 80001b14 <myproc>
    80002372:	89aa                	mv	s3,a0
  if(p == initproc)
    80002374:	00006797          	auipc	a5,0x6
    80002378:	5247b783          	ld	a5,1316(a5) # 80008898 <initproc>
    8000237c:	0d050493          	addi	s1,a0,208
    80002380:	15050913          	addi	s2,a0,336
    80002384:	02a79363          	bne	a5,a0,800023aa <exit+0x52>
    panic("init exiting");
    80002388:	00006517          	auipc	a0,0x6
    8000238c:	e9050513          	addi	a0,a0,-368 # 80008218 <digits+0x1d8>
    80002390:	ffffe097          	auipc	ra,0xffffe
    80002394:	1b4080e7          	jalr	436(ra) # 80000544 <panic>
      fileclose(f);
    80002398:	00002097          	auipc	ra,0x2
    8000239c:	326080e7          	jalr	806(ra) # 800046be <fileclose>
      p->ofile[fd] = 0;
    800023a0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023a4:	04a1                	addi	s1,s1,8
    800023a6:	01248563          	beq	s1,s2,800023b0 <exit+0x58>
    if(p->ofile[fd]){
    800023aa:	6088                	ld	a0,0(s1)
    800023ac:	f575                	bnez	a0,80002398 <exit+0x40>
    800023ae:	bfdd                	j	800023a4 <exit+0x4c>
  begin_op();
    800023b0:	00002097          	auipc	ra,0x2
    800023b4:	e42080e7          	jalr	-446(ra) # 800041f2 <begin_op>
  iput(p->cwd);
    800023b8:	1509b503          	ld	a0,336(s3)
    800023bc:	00001097          	auipc	ra,0x1
    800023c0:	62e080e7          	jalr	1582(ra) # 800039ea <iput>
  end_op();
    800023c4:	00002097          	auipc	ra,0x2
    800023c8:	eae080e7          	jalr	-338(ra) # 80004272 <end_op>
  p->cwd = 0;
    800023cc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023d0:	0000e497          	auipc	s1,0xe
    800023d4:	75848493          	addi	s1,s1,1880 # 80010b28 <wait_lock>
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	810080e7          	jalr	-2032(ra) # 80000bea <acquire>
  reparent(p);
    800023e2:	854e                	mv	a0,s3
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	f1a080e7          	jalr	-230(ra) # 800022fe <reparent>
  wakeup(p->parent);
    800023ec:	0389b503          	ld	a0,56(s3)
    800023f0:	00000097          	auipc	ra,0x0
    800023f4:	e98080e7          	jalr	-360(ra) # 80002288 <wakeup>
  acquire(&p->lock);
    800023f8:	854e                	mv	a0,s3
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	7f0080e7          	jalr	2032(ra) # 80000bea <acquire>
  p->xstate = status;
    80002402:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002406:	4795                	li	a5,5
    80002408:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	890080e7          	jalr	-1904(ra) # 80000c9e <release>
  sched();
    80002416:	00000097          	auipc	ra,0x0
    8000241a:	cfc080e7          	jalr	-772(ra) # 80002112 <sched>
  panic("zombie exit");
    8000241e:	00006517          	auipc	a0,0x6
    80002422:	e0a50513          	addi	a0,a0,-502 # 80008228 <digits+0x1e8>
    80002426:	ffffe097          	auipc	ra,0xffffe
    8000242a:	11e080e7          	jalr	286(ra) # 80000544 <panic>

000000008000242e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000242e:	7179                	addi	sp,sp,-48
    80002430:	f406                	sd	ra,40(sp)
    80002432:	f022                	sd	s0,32(sp)
    80002434:	ec26                	sd	s1,24(sp)
    80002436:	e84a                	sd	s2,16(sp)
    80002438:	e44e                	sd	s3,8(sp)
    8000243a:	1800                	addi	s0,sp,48
    8000243c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000243e:	0000f497          	auipc	s1,0xf
    80002442:	b0248493          	addi	s1,s1,-1278 # 80010f40 <proc>
    80002446:	00014997          	auipc	s3,0x14
    8000244a:	4fa98993          	addi	s3,s3,1274 # 80016940 <tickslock>
    acquire(&p->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	79a080e7          	jalr	1946(ra) # 80000bea <acquire>
    if(p->pid == pid){
    80002458:	589c                	lw	a5,48(s1)
    8000245a:	01278d63          	beq	a5,s2,80002474 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	83e080e7          	jalr	-1986(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002468:	16848493          	addi	s1,s1,360
    8000246c:	ff3491e3          	bne	s1,s3,8000244e <kill+0x20>
  }
  return -1;
    80002470:	557d                	li	a0,-1
    80002472:	a829                	j	8000248c <kill+0x5e>
      p->killed = 1;
    80002474:	4785                	li	a5,1
    80002476:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002478:	4c98                	lw	a4,24(s1)
    8000247a:	4789                	li	a5,2
    8000247c:	00f70f63          	beq	a4,a5,8000249a <kill+0x6c>
      release(&p->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	81c080e7          	jalr	-2020(ra) # 80000c9e <release>
      return 0;
    8000248a:	4501                	li	a0,0
}
    8000248c:	70a2                	ld	ra,40(sp)
    8000248e:	7402                	ld	s0,32(sp)
    80002490:	64e2                	ld	s1,24(sp)
    80002492:	6942                	ld	s2,16(sp)
    80002494:	69a2                	ld	s3,8(sp)
    80002496:	6145                	addi	sp,sp,48
    80002498:	8082                	ret
        p->state = RUNNABLE;
    8000249a:	478d                	li	a5,3
    8000249c:	cc9c                	sw	a5,24(s1)
    8000249e:	b7cd                	j	80002480 <kill+0x52>

00000000800024a0 <setkilled>:

void
setkilled(struct proc *p)
{
    800024a0:	1101                	addi	sp,sp,-32
    800024a2:	ec06                	sd	ra,24(sp)
    800024a4:	e822                	sd	s0,16(sp)
    800024a6:	e426                	sd	s1,8(sp)
    800024a8:	1000                	addi	s0,sp,32
    800024aa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	73e080e7          	jalr	1854(ra) # 80000bea <acquire>
  p->killed = 1;
    800024b4:	4785                	li	a5,1
    800024b6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024b8:	8526                	mv	a0,s1
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	7e4080e7          	jalr	2020(ra) # 80000c9e <release>
}
    800024c2:	60e2                	ld	ra,24(sp)
    800024c4:	6442                	ld	s0,16(sp)
    800024c6:	64a2                	ld	s1,8(sp)
    800024c8:	6105                	addi	sp,sp,32
    800024ca:	8082                	ret

00000000800024cc <killed>:

int
killed(struct proc *p)
{
    800024cc:	1101                	addi	sp,sp,-32
    800024ce:	ec06                	sd	ra,24(sp)
    800024d0:	e822                	sd	s0,16(sp)
    800024d2:	e426                	sd	s1,8(sp)
    800024d4:	e04a                	sd	s2,0(sp)
    800024d6:	1000                	addi	s0,sp,32
    800024d8:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	710080e7          	jalr	1808(ra) # 80000bea <acquire>
  k = p->killed;
    800024e2:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800024e6:	8526                	mv	a0,s1
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	7b6080e7          	jalr	1974(ra) # 80000c9e <release>
  return k;
}
    800024f0:	854a                	mv	a0,s2
    800024f2:	60e2                	ld	ra,24(sp)
    800024f4:	6442                	ld	s0,16(sp)
    800024f6:	64a2                	ld	s1,8(sp)
    800024f8:	6902                	ld	s2,0(sp)
    800024fa:	6105                	addi	sp,sp,32
    800024fc:	8082                	ret

00000000800024fe <wait>:
{
    800024fe:	715d                	addi	sp,sp,-80
    80002500:	e486                	sd	ra,72(sp)
    80002502:	e0a2                	sd	s0,64(sp)
    80002504:	fc26                	sd	s1,56(sp)
    80002506:	f84a                	sd	s2,48(sp)
    80002508:	f44e                	sd	s3,40(sp)
    8000250a:	f052                	sd	s4,32(sp)
    8000250c:	ec56                	sd	s5,24(sp)
    8000250e:	e85a                	sd	s6,16(sp)
    80002510:	e45e                	sd	s7,8(sp)
    80002512:	e062                	sd	s8,0(sp)
    80002514:	0880                	addi	s0,sp,80
    80002516:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	5fc080e7          	jalr	1532(ra) # 80001b14 <myproc>
    80002520:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002522:	0000e517          	auipc	a0,0xe
    80002526:	60650513          	addi	a0,a0,1542 # 80010b28 <wait_lock>
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	6c0080e7          	jalr	1728(ra) # 80000bea <acquire>
    havekids = 0;
    80002532:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002534:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002536:	00014997          	auipc	s3,0x14
    8000253a:	40a98993          	addi	s3,s3,1034 # 80016940 <tickslock>
        havekids = 1;
    8000253e:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002540:	0000ec17          	auipc	s8,0xe
    80002544:	5e8c0c13          	addi	s8,s8,1512 # 80010b28 <wait_lock>
    havekids = 0;
    80002548:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000254a:	0000f497          	auipc	s1,0xf
    8000254e:	9f648493          	addi	s1,s1,-1546 # 80010f40 <proc>
    80002552:	a0bd                	j	800025c0 <wait+0xc2>
          pid = pp->pid;
    80002554:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002558:	000b0e63          	beqz	s6,80002574 <wait+0x76>
    8000255c:	4691                	li	a3,4
    8000255e:	02c48613          	addi	a2,s1,44
    80002562:	85da                	mv	a1,s6
    80002564:	05093503          	ld	a0,80(s2)
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	26a080e7          	jalr	618(ra) # 800017d2 <copyout>
    80002570:	02054563          	bltz	a0,8000259a <wait+0x9c>
          freeproc(pp);
    80002574:	8526                	mv	a0,s1
    80002576:	fffff097          	auipc	ra,0xfffff
    8000257a:	750080e7          	jalr	1872(ra) # 80001cc6 <freeproc>
          release(&pp->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	71e080e7          	jalr	1822(ra) # 80000c9e <release>
          release(&wait_lock);
    80002588:	0000e517          	auipc	a0,0xe
    8000258c:	5a050513          	addi	a0,a0,1440 # 80010b28 <wait_lock>
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	70e080e7          	jalr	1806(ra) # 80000c9e <release>
          return pid;
    80002598:	a0b5                	j	80002604 <wait+0x106>
            release(&pp->lock);
    8000259a:	8526                	mv	a0,s1
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	702080e7          	jalr	1794(ra) # 80000c9e <release>
            release(&wait_lock);
    800025a4:	0000e517          	auipc	a0,0xe
    800025a8:	58450513          	addi	a0,a0,1412 # 80010b28 <wait_lock>
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	6f2080e7          	jalr	1778(ra) # 80000c9e <release>
            return -1;
    800025b4:	59fd                	li	s3,-1
    800025b6:	a0b9                	j	80002604 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025b8:	16848493          	addi	s1,s1,360
    800025bc:	03348463          	beq	s1,s3,800025e4 <wait+0xe6>
      if(pp->parent == p){
    800025c0:	7c9c                	ld	a5,56(s1)
    800025c2:	ff279be3          	bne	a5,s2,800025b8 <wait+0xba>
        acquire(&pp->lock);
    800025c6:	8526                	mv	a0,s1
    800025c8:	ffffe097          	auipc	ra,0xffffe
    800025cc:	622080e7          	jalr	1570(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    800025d0:	4c9c                	lw	a5,24(s1)
    800025d2:	f94781e3          	beq	a5,s4,80002554 <wait+0x56>
        release(&pp->lock);
    800025d6:	8526                	mv	a0,s1
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	6c6080e7          	jalr	1734(ra) # 80000c9e <release>
        havekids = 1;
    800025e0:	8756                	mv	a4,s5
    800025e2:	bfd9                	j	800025b8 <wait+0xba>
    if(!havekids || killed(p)){
    800025e4:	c719                	beqz	a4,800025f2 <wait+0xf4>
    800025e6:	854a                	mv	a0,s2
    800025e8:	00000097          	auipc	ra,0x0
    800025ec:	ee4080e7          	jalr	-284(ra) # 800024cc <killed>
    800025f0:	c51d                	beqz	a0,8000261e <wait+0x120>
      release(&wait_lock);
    800025f2:	0000e517          	auipc	a0,0xe
    800025f6:	53650513          	addi	a0,a0,1334 # 80010b28 <wait_lock>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	6a4080e7          	jalr	1700(ra) # 80000c9e <release>
      return -1;
    80002602:	59fd                	li	s3,-1
}
    80002604:	854e                	mv	a0,s3
    80002606:	60a6                	ld	ra,72(sp)
    80002608:	6406                	ld	s0,64(sp)
    8000260a:	74e2                	ld	s1,56(sp)
    8000260c:	7942                	ld	s2,48(sp)
    8000260e:	79a2                	ld	s3,40(sp)
    80002610:	7a02                	ld	s4,32(sp)
    80002612:	6ae2                	ld	s5,24(sp)
    80002614:	6b42                	ld	s6,16(sp)
    80002616:	6ba2                	ld	s7,8(sp)
    80002618:	6c02                	ld	s8,0(sp)
    8000261a:	6161                	addi	sp,sp,80
    8000261c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000261e:	85e2                	mv	a1,s8
    80002620:	854a                	mv	a0,s2
    80002622:	00000097          	auipc	ra,0x0
    80002626:	c02080e7          	jalr	-1022(ra) # 80002224 <sleep>
    havekids = 0;
    8000262a:	bf39                	j	80002548 <wait+0x4a>

000000008000262c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000262c:	7179                	addi	sp,sp,-48
    8000262e:	f406                	sd	ra,40(sp)
    80002630:	f022                	sd	s0,32(sp)
    80002632:	ec26                	sd	s1,24(sp)
    80002634:	e84a                	sd	s2,16(sp)
    80002636:	e44e                	sd	s3,8(sp)
    80002638:	e052                	sd	s4,0(sp)
    8000263a:	1800                	addi	s0,sp,48
    8000263c:	84aa                	mv	s1,a0
    8000263e:	892e                	mv	s2,a1
    80002640:	89b2                	mv	s3,a2
    80002642:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	4d0080e7          	jalr	1232(ra) # 80001b14 <myproc>
  if(user_dst){
    8000264c:	c08d                	beqz	s1,8000266e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000264e:	86d2                	mv	a3,s4
    80002650:	864e                	mv	a2,s3
    80002652:	85ca                	mv	a1,s2
    80002654:	6928                	ld	a0,80(a0)
    80002656:	fffff097          	auipc	ra,0xfffff
    8000265a:	17c080e7          	jalr	380(ra) # 800017d2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000265e:	70a2                	ld	ra,40(sp)
    80002660:	7402                	ld	s0,32(sp)
    80002662:	64e2                	ld	s1,24(sp)
    80002664:	6942                	ld	s2,16(sp)
    80002666:	69a2                	ld	s3,8(sp)
    80002668:	6a02                	ld	s4,0(sp)
    8000266a:	6145                	addi	sp,sp,48
    8000266c:	8082                	ret
    memmove((char *)dst, src, len);
    8000266e:	000a061b          	sext.w	a2,s4
    80002672:	85ce                	mv	a1,s3
    80002674:	854a                	mv	a0,s2
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	6d0080e7          	jalr	1744(ra) # 80000d46 <memmove>
    return 0;
    8000267e:	8526                	mv	a0,s1
    80002680:	bff9                	j	8000265e <either_copyout+0x32>

0000000080002682 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002682:	7179                	addi	sp,sp,-48
    80002684:	f406                	sd	ra,40(sp)
    80002686:	f022                	sd	s0,32(sp)
    80002688:	ec26                	sd	s1,24(sp)
    8000268a:	e84a                	sd	s2,16(sp)
    8000268c:	e44e                	sd	s3,8(sp)
    8000268e:	e052                	sd	s4,0(sp)
    80002690:	1800                	addi	s0,sp,48
    80002692:	892a                	mv	s2,a0
    80002694:	84ae                	mv	s1,a1
    80002696:	89b2                	mv	s3,a2
    80002698:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000269a:	fffff097          	auipc	ra,0xfffff
    8000269e:	47a080e7          	jalr	1146(ra) # 80001b14 <myproc>
  if(user_src){
    800026a2:	c08d                	beqz	s1,800026c4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026a4:	86d2                	mv	a3,s4
    800026a6:	864e                	mv	a2,s3
    800026a8:	85ca                	mv	a1,s2
    800026aa:	6928                	ld	a0,80(a0)
    800026ac:	fffff097          	auipc	ra,0xfffff
    800026b0:	1b2080e7          	jalr	434(ra) # 8000185e <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800026b4:	70a2                	ld	ra,40(sp)
    800026b6:	7402                	ld	s0,32(sp)
    800026b8:	64e2                	ld	s1,24(sp)
    800026ba:	6942                	ld	s2,16(sp)
    800026bc:	69a2                	ld	s3,8(sp)
    800026be:	6a02                	ld	s4,0(sp)
    800026c0:	6145                	addi	sp,sp,48
    800026c2:	8082                	ret
    memmove(dst, (char*)src, len);
    800026c4:	000a061b          	sext.w	a2,s4
    800026c8:	85ce                	mv	a1,s3
    800026ca:	854a                	mv	a0,s2
    800026cc:	ffffe097          	auipc	ra,0xffffe
    800026d0:	67a080e7          	jalr	1658(ra) # 80000d46 <memmove>
    return 0;
    800026d4:	8526                	mv	a0,s1
    800026d6:	bff9                	j	800026b4 <either_copyin+0x32>

00000000800026d8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026d8:	715d                	addi	sp,sp,-80
    800026da:	e486                	sd	ra,72(sp)
    800026dc:	e0a2                	sd	s0,64(sp)
    800026de:	fc26                	sd	s1,56(sp)
    800026e0:	f84a                	sd	s2,48(sp)
    800026e2:	f44e                	sd	s3,40(sp)
    800026e4:	f052                	sd	s4,32(sp)
    800026e6:	ec56                	sd	s5,24(sp)
    800026e8:	e85a                	sd	s6,16(sp)
    800026ea:	e45e                	sd	s7,8(sp)
    800026ec:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026ee:	00006517          	auipc	a0,0x6
    800026f2:	9da50513          	addi	a0,a0,-1574 # 800080c8 <digits+0x88>
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	e98080e7          	jalr	-360(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026fe:	0000f497          	auipc	s1,0xf
    80002702:	99a48493          	addi	s1,s1,-1638 # 80011098 <proc+0x158>
    80002706:	00014917          	auipc	s2,0x14
    8000270a:	39290913          	addi	s2,s2,914 # 80016a98 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000270e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002710:	00006997          	auipc	s3,0x6
    80002714:	b2898993          	addi	s3,s3,-1240 # 80008238 <digits+0x1f8>
    printf("%d %s %s", p->pid, state, p->name);
    80002718:	00006a97          	auipc	s5,0x6
    8000271c:	b28a8a93          	addi	s5,s5,-1240 # 80008240 <digits+0x200>
    printf("\n");
    80002720:	00006a17          	auipc	s4,0x6
    80002724:	9a8a0a13          	addi	s4,s4,-1624 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002728:	00006b97          	auipc	s7,0x6
    8000272c:	b58b8b93          	addi	s7,s7,-1192 # 80008280 <states.1736>
    80002730:	a00d                	j	80002752 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002732:	ed86a583          	lw	a1,-296(a3)
    80002736:	8556                	mv	a0,s5
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	e56080e7          	jalr	-426(ra) # 8000058e <printf>
    printf("\n");
    80002740:	8552                	mv	a0,s4
    80002742:	ffffe097          	auipc	ra,0xffffe
    80002746:	e4c080e7          	jalr	-436(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000274a:	16848493          	addi	s1,s1,360
    8000274e:	03248163          	beq	s1,s2,80002770 <procdump+0x98>
    if(p->state == UNUSED)
    80002752:	86a6                	mv	a3,s1
    80002754:	ec04a783          	lw	a5,-320(s1)
    80002758:	dbed                	beqz	a5,8000274a <procdump+0x72>
      state = "???";
    8000275a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000275c:	fcfb6be3          	bltu	s6,a5,80002732 <procdump+0x5a>
    80002760:	1782                	slli	a5,a5,0x20
    80002762:	9381                	srli	a5,a5,0x20
    80002764:	078e                	slli	a5,a5,0x3
    80002766:	97de                	add	a5,a5,s7
    80002768:	6390                	ld	a2,0(a5)
    8000276a:	f661                	bnez	a2,80002732 <procdump+0x5a>
      state = "???";
    8000276c:	864e                	mv	a2,s3
    8000276e:	b7d1                	j	80002732 <procdump+0x5a>
  }
}
    80002770:	60a6                	ld	ra,72(sp)
    80002772:	6406                	ld	s0,64(sp)
    80002774:	74e2                	ld	s1,56(sp)
    80002776:	7942                	ld	s2,48(sp)
    80002778:	79a2                	ld	s3,40(sp)
    8000277a:	7a02                	ld	s4,32(sp)
    8000277c:	6ae2                	ld	s5,24(sp)
    8000277e:	6b42                	ld	s6,16(sp)
    80002780:	6ba2                	ld	s7,8(sp)
    80002782:	6161                	addi	sp,sp,80
    80002784:	8082                	ret

0000000080002786 <swtch>:
    80002786:	00153023          	sd	ra,0(a0)
    8000278a:	00253423          	sd	sp,8(a0)
    8000278e:	e900                	sd	s0,16(a0)
    80002790:	ed04                	sd	s1,24(a0)
    80002792:	03253023          	sd	s2,32(a0)
    80002796:	03353423          	sd	s3,40(a0)
    8000279a:	03453823          	sd	s4,48(a0)
    8000279e:	03553c23          	sd	s5,56(a0)
    800027a2:	05653023          	sd	s6,64(a0)
    800027a6:	05753423          	sd	s7,72(a0)
    800027aa:	05853823          	sd	s8,80(a0)
    800027ae:	05953c23          	sd	s9,88(a0)
    800027b2:	07a53023          	sd	s10,96(a0)
    800027b6:	07b53423          	sd	s11,104(a0)
    800027ba:	0005b083          	ld	ra,0(a1)
    800027be:	0085b103          	ld	sp,8(a1)
    800027c2:	6980                	ld	s0,16(a1)
    800027c4:	6d84                	ld	s1,24(a1)
    800027c6:	0205b903          	ld	s2,32(a1)
    800027ca:	0285b983          	ld	s3,40(a1)
    800027ce:	0305ba03          	ld	s4,48(a1)
    800027d2:	0385ba83          	ld	s5,56(a1)
    800027d6:	0405bb03          	ld	s6,64(a1)
    800027da:	0485bb83          	ld	s7,72(a1)
    800027de:	0505bc03          	ld	s8,80(a1)
    800027e2:	0585bc83          	ld	s9,88(a1)
    800027e6:	0605bd03          	ld	s10,96(a1)
    800027ea:	0685bd83          	ld	s11,104(a1)
    800027ee:	8082                	ret

00000000800027f0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027f0:	1141                	addi	sp,sp,-16
    800027f2:	e406                	sd	ra,8(sp)
    800027f4:	e022                	sd	s0,0(sp)
    800027f6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027f8:	00006597          	auipc	a1,0x6
    800027fc:	ab858593          	addi	a1,a1,-1352 # 800082b0 <states.1736+0x30>
    80002800:	00014517          	auipc	a0,0x14
    80002804:	14050513          	addi	a0,a0,320 # 80016940 <tickslock>
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	352080e7          	jalr	850(ra) # 80000b5a <initlock>
}
    80002810:	60a2                	ld	ra,8(sp)
    80002812:	6402                	ld	s0,0(sp)
    80002814:	0141                	addi	sp,sp,16
    80002816:	8082                	ret

0000000080002818 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002818:	1141                	addi	sp,sp,-16
    8000281a:	e422                	sd	s0,8(sp)
    8000281c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000281e:	00003797          	auipc	a5,0x3
    80002822:	4f278793          	addi	a5,a5,1266 # 80005d10 <kernelvec>
    80002826:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000282a:	6422                	ld	s0,8(sp)
    8000282c:	0141                	addi	sp,sp,16
    8000282e:	8082                	ret

0000000080002830 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002830:	1141                	addi	sp,sp,-16
    80002832:	e406                	sd	ra,8(sp)
    80002834:	e022                	sd	s0,0(sp)
    80002836:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	2dc080e7          	jalr	732(ra) # 80001b14 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002840:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002844:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002846:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000284a:	00004617          	auipc	a2,0x4
    8000284e:	7b660613          	addi	a2,a2,1974 # 80007000 <_trampoline>
    80002852:	00004697          	auipc	a3,0x4
    80002856:	7ae68693          	addi	a3,a3,1966 # 80007000 <_trampoline>
    8000285a:	8e91                	sub	a3,a3,a2
    8000285c:	040007b7          	lui	a5,0x4000
    80002860:	17fd                	addi	a5,a5,-1
    80002862:	07b2                	slli	a5,a5,0xc
    80002864:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002866:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000286a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000286c:	180026f3          	csrr	a3,satp
    80002870:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002872:	6d38                	ld	a4,88(a0)
    80002874:	6134                	ld	a3,64(a0)
    80002876:	6585                	lui	a1,0x1
    80002878:	96ae                	add	a3,a3,a1
    8000287a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000287c:	6d38                	ld	a4,88(a0)
    8000287e:	00000697          	auipc	a3,0x0
    80002882:	13068693          	addi	a3,a3,304 # 800029ae <usertrap>
    80002886:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002888:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000288a:	8692                	mv	a3,tp
    8000288c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002892:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002896:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000289e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028a0:	6f18                	ld	a4,24(a4)
    800028a2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028a6:	6928                	ld	a0,80(a0)
    800028a8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028aa:	00004717          	auipc	a4,0x4
    800028ae:	7f270713          	addi	a4,a4,2034 # 8000709c <userret>
    800028b2:	8f11                	sub	a4,a4,a2
    800028b4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028b6:	577d                	li	a4,-1
    800028b8:	177e                	slli	a4,a4,0x3f
    800028ba:	8d59                	or	a0,a0,a4
    800028bc:	9782                	jalr	a5
}
    800028be:	60a2                	ld	ra,8(sp)
    800028c0:	6402                	ld	s0,0(sp)
    800028c2:	0141                	addi	sp,sp,16
    800028c4:	8082                	ret

00000000800028c6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028c6:	1101                	addi	sp,sp,-32
    800028c8:	ec06                	sd	ra,24(sp)
    800028ca:	e822                	sd	s0,16(sp)
    800028cc:	e426                	sd	s1,8(sp)
    800028ce:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028d0:	00014497          	auipc	s1,0x14
    800028d4:	07048493          	addi	s1,s1,112 # 80016940 <tickslock>
    800028d8:	8526                	mv	a0,s1
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	310080e7          	jalr	784(ra) # 80000bea <acquire>
  ticks++;
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	fbe50513          	addi	a0,a0,-66 # 800088a0 <ticks>
    800028ea:	411c                	lw	a5,0(a0)
    800028ec:	2785                	addiw	a5,a5,1
    800028ee:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	998080e7          	jalr	-1640(ra) # 80002288 <wakeup>
  release(&tickslock);
    800028f8:	8526                	mv	a0,s1
    800028fa:	ffffe097          	auipc	ra,0xffffe
    800028fe:	3a4080e7          	jalr	932(ra) # 80000c9e <release>
}
    80002902:	60e2                	ld	ra,24(sp)
    80002904:	6442                	ld	s0,16(sp)
    80002906:	64a2                	ld	s1,8(sp)
    80002908:	6105                	addi	sp,sp,32
    8000290a:	8082                	ret

000000008000290c <devintr>:
// 1 if other device,
// 0 if not recognized.
int

devintr()
{
    8000290c:	1101                	addi	sp,sp,-32
    8000290e:	ec06                	sd	ra,24(sp)
    80002910:	e822                	sd	s0,16(sp)
    80002912:	e426                	sd	s1,8(sp)
    80002914:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002916:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000291a:	00074d63          	bltz	a4,80002934 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000291e:	57fd                	li	a5,-1
    80002920:	17fe                	slli	a5,a5,0x3f
    80002922:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002924:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002926:	06f70363          	beq	a4,a5,8000298c <devintr+0x80>
  }
}
    8000292a:	60e2                	ld	ra,24(sp)
    8000292c:	6442                	ld	s0,16(sp)
    8000292e:	64a2                	ld	s1,8(sp)
    80002930:	6105                	addi	sp,sp,32
    80002932:	8082                	ret
     (scause & 0xff) == 9){
    80002934:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002938:	46a5                	li	a3,9
    8000293a:	fed792e3          	bne	a5,a3,8000291e <devintr+0x12>
    int irq = plic_claim();
    8000293e:	00003097          	auipc	ra,0x3
    80002942:	4da080e7          	jalr	1242(ra) # 80005e18 <plic_claim>
    80002946:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002948:	47a9                	li	a5,10
    8000294a:	02f50763          	beq	a0,a5,80002978 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000294e:	4785                	li	a5,1
    80002950:	02f50963          	beq	a0,a5,80002982 <devintr+0x76>
    return 1;
    80002954:	4505                	li	a0,1
    } else if(irq){
    80002956:	d8f1                	beqz	s1,8000292a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002958:	85a6                	mv	a1,s1
    8000295a:	00006517          	auipc	a0,0x6
    8000295e:	95e50513          	addi	a0,a0,-1698 # 800082b8 <states.1736+0x38>
    80002962:	ffffe097          	auipc	ra,0xffffe
    80002966:	c2c080e7          	jalr	-980(ra) # 8000058e <printf>
      plic_complete(irq);
    8000296a:	8526                	mv	a0,s1
    8000296c:	00003097          	auipc	ra,0x3
    80002970:	4d0080e7          	jalr	1232(ra) # 80005e3c <plic_complete>
    return 1;
    80002974:	4505                	li	a0,1
    80002976:	bf55                	j	8000292a <devintr+0x1e>
      uartintr();
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	036080e7          	jalr	54(ra) # 800009ae <uartintr>
    80002980:	b7ed                	j	8000296a <devintr+0x5e>
      virtio_disk_intr();
    80002982:	00004097          	auipc	ra,0x4
    80002986:	9e4080e7          	jalr	-1564(ra) # 80006366 <virtio_disk_intr>
    8000298a:	b7c5                	j	8000296a <devintr+0x5e>
    if(cpuid() == 0){
    8000298c:	fffff097          	auipc	ra,0xfffff
    80002990:	15c080e7          	jalr	348(ra) # 80001ae8 <cpuid>
    80002994:	c901                	beqz	a0,800029a4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002996:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000299a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000299c:	14479073          	csrw	sip,a5
    return 2;
    800029a0:	4509                	li	a0,2
    800029a2:	b761                	j	8000292a <devintr+0x1e>
      clockintr();
    800029a4:	00000097          	auipc	ra,0x0
    800029a8:	f22080e7          	jalr	-222(ra) # 800028c6 <clockintr>
    800029ac:	b7ed                	j	80002996 <devintr+0x8a>

00000000800029ae <usertrap>:
{
    800029ae:	1101                	addi	sp,sp,-32
    800029b0:	ec06                	sd	ra,24(sp)
    800029b2:	e822                	sd	s0,16(sp)
    800029b4:	e426                	sd	s1,8(sp)
    800029b6:	e04a                	sd	s2,0(sp)
    800029b8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ba:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029be:	1007f793          	andi	a5,a5,256
    800029c2:	efa5                	bnez	a5,80002a3a <usertrap+0x8c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c4:	00003797          	auipc	a5,0x3
    800029c8:	34c78793          	addi	a5,a5,844 # 80005d10 <kernelvec>
    800029cc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029d0:	fffff097          	auipc	ra,0xfffff
    800029d4:	144080e7          	jalr	324(ra) # 80001b14 <myproc>
    800029d8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029da:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029dc:	14102773          	csrr	a4,sepc
    800029e0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029e2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029e6:	47a1                	li	a5,8
    800029e8:	06f70163          	beq	a4,a5,80002a4a <usertrap+0x9c>
    800029ec:	14202773          	csrr	a4,scause
  }   else if (r_scause() == 13 || r_scause() == 15) {
    800029f0:	47b5                	li	a5,13
    800029f2:	00f70763          	beq	a4,a5,80002a00 <usertrap+0x52>
    800029f6:	14202773          	csrr	a4,scause
    800029fa:	47bd                	li	a5,15
    800029fc:	08f71163          	bne	a4,a5,80002a7e <usertrap+0xd0>
    if (lazyalloc(myproc(), r_stval()) <= 0) {
    80002a00:	fffff097          	auipc	ra,0xfffff
    80002a04:	114080e7          	jalr	276(ra) # 80001b14 <myproc>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a08:	143025f3          	csrr	a1,stval
    80002a0c:	fffff097          	auipc	ra,0xfffff
    80002a10:	cf4080e7          	jalr	-780(ra) # 80001700 <lazyalloc>
    80002a14:	e119                	bnez	a0,80002a1a <usertrap+0x6c>
      p->killed = 1;
    80002a16:	4785                	li	a5,1
    80002a18:	d49c                	sw	a5,40(s1)
  if(killed(p))
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	00000097          	auipc	ra,0x0
    80002a20:	ab0080e7          	jalr	-1360(ra) # 800024cc <killed>
    80002a24:	e55d                	bnez	a0,80002ad2 <usertrap+0x124>
  usertrapret();
    80002a26:	00000097          	auipc	ra,0x0
    80002a2a:	e0a080e7          	jalr	-502(ra) # 80002830 <usertrapret>
}
    80002a2e:	60e2                	ld	ra,24(sp)
    80002a30:	6442                	ld	s0,16(sp)
    80002a32:	64a2                	ld	s1,8(sp)
    80002a34:	6902                	ld	s2,0(sp)
    80002a36:	6105                	addi	sp,sp,32
    80002a38:	8082                	ret
    panic("usertrap: not from user mode");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	89e50513          	addi	a0,a0,-1890 # 800082d8 <states.1736+0x58>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b02080e7          	jalr	-1278(ra) # 80000544 <panic>
    if(killed(p))
    80002a4a:	00000097          	auipc	ra,0x0
    80002a4e:	a82080e7          	jalr	-1406(ra) # 800024cc <killed>
    80002a52:	e105                	bnez	a0,80002a72 <usertrap+0xc4>
    p->trapframe->epc += 4;
    80002a54:	6cb8                	ld	a4,88(s1)
    80002a56:	6f1c                	ld	a5,24(a4)
    80002a58:	0791                	addi	a5,a5,4
    80002a5a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a60:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a64:	10079073          	csrw	sstatus,a5
    syscall();
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	2d0080e7          	jalr	720(ra) # 80002d38 <syscall>
    80002a70:	b76d                	j	80002a1a <usertrap+0x6c>
      exit(-1);
    80002a72:	557d                	li	a0,-1
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	8e4080e7          	jalr	-1820(ra) # 80002358 <exit>
    80002a7c:	bfe1                	j	80002a54 <usertrap+0xa6>
  } else if((which_dev = devintr()) != 0){
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	e8e080e7          	jalr	-370(ra) # 8000290c <devintr>
    80002a86:	892a                	mv	s2,a0
    80002a88:	c901                	beqz	a0,80002a98 <usertrap+0xea>
  if(killed(p))
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	00000097          	auipc	ra,0x0
    80002a90:	a40080e7          	jalr	-1472(ra) # 800024cc <killed>
    80002a94:	c529                	beqz	a0,80002ade <usertrap+0x130>
    80002a96:	a83d                	j	80002ad4 <usertrap+0x126>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a98:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a9c:	5890                	lw	a2,48(s1)
    80002a9e:	00006517          	auipc	a0,0x6
    80002aa2:	85a50513          	addi	a0,a0,-1958 # 800082f8 <states.1736+0x78>
    80002aa6:	ffffe097          	auipc	ra,0xffffe
    80002aaa:	ae8080e7          	jalr	-1304(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aae:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	87250513          	addi	a0,a0,-1934 # 80008328 <states.1736+0xa8>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	ad0080e7          	jalr	-1328(ra) # 8000058e <printf>
    setkilled(p);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	9d8080e7          	jalr	-1576(ra) # 800024a0 <setkilled>
    80002ad0:	b7a9                	j	80002a1a <usertrap+0x6c>
  if(killed(p))
    80002ad2:	4901                	li	s2,0
    exit(-1);
    80002ad4:	557d                	li	a0,-1
    80002ad6:	00000097          	auipc	ra,0x0
    80002ada:	882080e7          	jalr	-1918(ra) # 80002358 <exit>
  if(which_dev == 2)
    80002ade:	4789                	li	a5,2
    80002ae0:	f4f913e3          	bne	s2,a5,80002a26 <usertrap+0x78>
    yield();
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	704080e7          	jalr	1796(ra) # 800021e8 <yield>
    80002aec:	bf2d                	j	80002a26 <usertrap+0x78>

0000000080002aee <kerneltrap>:
{
    80002aee:	7179                	addi	sp,sp,-48
    80002af0:	f406                	sd	ra,40(sp)
    80002af2:	f022                	sd	s0,32(sp)
    80002af4:	ec26                	sd	s1,24(sp)
    80002af6:	e84a                	sd	s2,16(sp)
    80002af8:	e44e                	sd	s3,8(sp)
    80002afa:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b00:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b04:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b08:	1004f793          	andi	a5,s1,256
    80002b0c:	cb85                	beqz	a5,80002b3c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b0e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b12:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b14:	ef85                	bnez	a5,80002b4c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b16:	00000097          	auipc	ra,0x0
    80002b1a:	df6080e7          	jalr	-522(ra) # 8000290c <devintr>
    80002b1e:	cd1d                	beqz	a0,80002b5c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b20:	4789                	li	a5,2
    80002b22:	06f50a63          	beq	a0,a5,80002b96 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b26:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b2a:	10049073          	csrw	sstatus,s1
}
    80002b2e:	70a2                	ld	ra,40(sp)
    80002b30:	7402                	ld	s0,32(sp)
    80002b32:	64e2                	ld	s1,24(sp)
    80002b34:	6942                	ld	s2,16(sp)
    80002b36:	69a2                	ld	s3,8(sp)
    80002b38:	6145                	addi	sp,sp,48
    80002b3a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b3c:	00006517          	auipc	a0,0x6
    80002b40:	80c50513          	addi	a0,a0,-2036 # 80008348 <states.1736+0xc8>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	a00080e7          	jalr	-1536(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b4c:	00006517          	auipc	a0,0x6
    80002b50:	82450513          	addi	a0,a0,-2012 # 80008370 <states.1736+0xf0>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	9f0080e7          	jalr	-1552(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002b5c:	85ce                	mv	a1,s3
    80002b5e:	00006517          	auipc	a0,0x6
    80002b62:	83250513          	addi	a0,a0,-1998 # 80008390 <states.1736+0x110>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	a28080e7          	jalr	-1496(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b72:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b76:	00006517          	auipc	a0,0x6
    80002b7a:	82a50513          	addi	a0,a0,-2006 # 800083a0 <states.1736+0x120>
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	a10080e7          	jalr	-1520(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002b86:	00006517          	auipc	a0,0x6
    80002b8a:	83250513          	addi	a0,a0,-1998 # 800083b8 <states.1736+0x138>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	9b6080e7          	jalr	-1610(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	f7e080e7          	jalr	-130(ra) # 80001b14 <myproc>
    80002b9e:	d541                	beqz	a0,80002b26 <kerneltrap+0x38>
    80002ba0:	fffff097          	auipc	ra,0xfffff
    80002ba4:	f74080e7          	jalr	-140(ra) # 80001b14 <myproc>
    80002ba8:	4d18                	lw	a4,24(a0)
    80002baa:	4791                	li	a5,4
    80002bac:	f6f71de3          	bne	a4,a5,80002b26 <kerneltrap+0x38>
    yield();
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	638080e7          	jalr	1592(ra) # 800021e8 <yield>
    80002bb8:	b7bd                	j	80002b26 <kerneltrap+0x38>

0000000080002bba <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bba:	1101                	addi	sp,sp,-32
    80002bbc:	ec06                	sd	ra,24(sp)
    80002bbe:	e822                	sd	s0,16(sp)
    80002bc0:	e426                	sd	s1,8(sp)
    80002bc2:	1000                	addi	s0,sp,32
    80002bc4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	f4e080e7          	jalr	-178(ra) # 80001b14 <myproc>
  switch (n) {
    80002bce:	4795                	li	a5,5
    80002bd0:	0497e163          	bltu	a5,s1,80002c12 <argraw+0x58>
    80002bd4:	048a                	slli	s1,s1,0x2
    80002bd6:	00006717          	auipc	a4,0x6
    80002bda:	81a70713          	addi	a4,a4,-2022 # 800083f0 <states.1736+0x170>
    80002bde:	94ba                	add	s1,s1,a4
    80002be0:	409c                	lw	a5,0(s1)
    80002be2:	97ba                	add	a5,a5,a4
    80002be4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002be6:	6d3c                	ld	a5,88(a0)
    80002be8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret
    return p->trapframe->a1;
    80002bf4:	6d3c                	ld	a5,88(a0)
    80002bf6:	7fa8                	ld	a0,120(a5)
    80002bf8:	bfcd                	j	80002bea <argraw+0x30>
    return p->trapframe->a2;
    80002bfa:	6d3c                	ld	a5,88(a0)
    80002bfc:	63c8                	ld	a0,128(a5)
    80002bfe:	b7f5                	j	80002bea <argraw+0x30>
    return p->trapframe->a3;
    80002c00:	6d3c                	ld	a5,88(a0)
    80002c02:	67c8                	ld	a0,136(a5)
    80002c04:	b7dd                	j	80002bea <argraw+0x30>
    return p->trapframe->a4;
    80002c06:	6d3c                	ld	a5,88(a0)
    80002c08:	6bc8                	ld	a0,144(a5)
    80002c0a:	b7c5                	j	80002bea <argraw+0x30>
    return p->trapframe->a5;
    80002c0c:	6d3c                	ld	a5,88(a0)
    80002c0e:	6fc8                	ld	a0,152(a5)
    80002c10:	bfe9                	j	80002bea <argraw+0x30>
  panic("argraw");
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	7b650513          	addi	a0,a0,1974 # 800083c8 <states.1736+0x148>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	92a080e7          	jalr	-1750(ra) # 80000544 <panic>

0000000080002c22 <fetchaddr>:
{
    80002c22:	1101                	addi	sp,sp,-32
    80002c24:	ec06                	sd	ra,24(sp)
    80002c26:	e822                	sd	s0,16(sp)
    80002c28:	e426                	sd	s1,8(sp)
    80002c2a:	e04a                	sd	s2,0(sp)
    80002c2c:	1000                	addi	s0,sp,32
    80002c2e:	84aa                	mv	s1,a0
    80002c30:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	ee2080e7          	jalr	-286(ra) # 80001b14 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c3a:	653c                	ld	a5,72(a0)
    80002c3c:	02f4f863          	bgeu	s1,a5,80002c6c <fetchaddr+0x4a>
    80002c40:	00848713          	addi	a4,s1,8
    80002c44:	02e7e663          	bltu	a5,a4,80002c70 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c48:	46a1                	li	a3,8
    80002c4a:	8626                	mv	a2,s1
    80002c4c:	85ca                	mv	a1,s2
    80002c4e:	6928                	ld	a0,80(a0)
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	c0e080e7          	jalr	-1010(ra) # 8000185e <copyin>
    80002c58:	00a03533          	snez	a0,a0
    80002c5c:	40a00533          	neg	a0,a0
}
    80002c60:	60e2                	ld	ra,24(sp)
    80002c62:	6442                	ld	s0,16(sp)
    80002c64:	64a2                	ld	s1,8(sp)
    80002c66:	6902                	ld	s2,0(sp)
    80002c68:	6105                	addi	sp,sp,32
    80002c6a:	8082                	ret
    return -1;
    80002c6c:	557d                	li	a0,-1
    80002c6e:	bfcd                	j	80002c60 <fetchaddr+0x3e>
    80002c70:	557d                	li	a0,-1
    80002c72:	b7fd                	j	80002c60 <fetchaddr+0x3e>

0000000080002c74 <fetchstr>:
{
    80002c74:	7179                	addi	sp,sp,-48
    80002c76:	f406                	sd	ra,40(sp)
    80002c78:	f022                	sd	s0,32(sp)
    80002c7a:	ec26                	sd	s1,24(sp)
    80002c7c:	e84a                	sd	s2,16(sp)
    80002c7e:	e44e                	sd	s3,8(sp)
    80002c80:	1800                	addi	s0,sp,48
    80002c82:	892a                	mv	s2,a0
    80002c84:	84ae                	mv	s1,a1
    80002c86:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	e8c080e7          	jalr	-372(ra) # 80001b14 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c90:	86ce                	mv	a3,s3
    80002c92:	864a                	mv	a2,s2
    80002c94:	85a6                	mv	a1,s1
    80002c96:	6928                	ld	a0,80(a0)
    80002c98:	fffff097          	auipc	ra,0xfffff
    80002c9c:	c52080e7          	jalr	-942(ra) # 800018ea <copyinstr>
    80002ca0:	00054e63          	bltz	a0,80002cbc <fetchstr+0x48>
  return strlen(buf);
    80002ca4:	8526                	mv	a0,s1
    80002ca6:	ffffe097          	auipc	ra,0xffffe
    80002caa:	1c4080e7          	jalr	452(ra) # 80000e6a <strlen>
}
    80002cae:	70a2                	ld	ra,40(sp)
    80002cb0:	7402                	ld	s0,32(sp)
    80002cb2:	64e2                	ld	s1,24(sp)
    80002cb4:	6942                	ld	s2,16(sp)
    80002cb6:	69a2                	ld	s3,8(sp)
    80002cb8:	6145                	addi	sp,sp,48
    80002cba:	8082                	ret
    return -1;
    80002cbc:	557d                	li	a0,-1
    80002cbe:	bfc5                	j	80002cae <fetchstr+0x3a>

0000000080002cc0 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	1000                	addi	s0,sp,32
    80002cca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	eee080e7          	jalr	-274(ra) # 80002bba <argraw>
    80002cd4:	c088                	sw	a0,0(s1)
}
    80002cd6:	60e2                	ld	ra,24(sp)
    80002cd8:	6442                	ld	s0,16(sp)
    80002cda:	64a2                	ld	s1,8(sp)
    80002cdc:	6105                	addi	sp,sp,32
    80002cde:	8082                	ret

0000000080002ce0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	e426                	sd	s1,8(sp)
    80002ce8:	1000                	addi	s0,sp,32
    80002cea:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cec:	00000097          	auipc	ra,0x0
    80002cf0:	ece080e7          	jalr	-306(ra) # 80002bba <argraw>
    80002cf4:	e088                	sd	a0,0(s1)
}
    80002cf6:	60e2                	ld	ra,24(sp)
    80002cf8:	6442                	ld	s0,16(sp)
    80002cfa:	64a2                	ld	s1,8(sp)
    80002cfc:	6105                	addi	sp,sp,32
    80002cfe:	8082                	ret

0000000080002d00 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d00:	7179                	addi	sp,sp,-48
    80002d02:	f406                	sd	ra,40(sp)
    80002d04:	f022                	sd	s0,32(sp)
    80002d06:	ec26                	sd	s1,24(sp)
    80002d08:	e84a                	sd	s2,16(sp)
    80002d0a:	1800                	addi	s0,sp,48
    80002d0c:	84ae                	mv	s1,a1
    80002d0e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d10:	fd840593          	addi	a1,s0,-40
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	fcc080e7          	jalr	-52(ra) # 80002ce0 <argaddr>
  return fetchstr(addr, buf, max);
    80002d1c:	864a                	mv	a2,s2
    80002d1e:	85a6                	mv	a1,s1
    80002d20:	fd843503          	ld	a0,-40(s0)
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	f50080e7          	jalr	-176(ra) # 80002c74 <fetchstr>
}
    80002d2c:	70a2                	ld	ra,40(sp)
    80002d2e:	7402                	ld	s0,32(sp)
    80002d30:	64e2                	ld	s1,24(sp)
    80002d32:	6942                	ld	s2,16(sp)
    80002d34:	6145                	addi	sp,sp,48
    80002d36:	8082                	ret

0000000080002d38 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d38:	1101                	addi	sp,sp,-32
    80002d3a:	ec06                	sd	ra,24(sp)
    80002d3c:	e822                	sd	s0,16(sp)
    80002d3e:	e426                	sd	s1,8(sp)
    80002d40:	e04a                	sd	s2,0(sp)
    80002d42:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	dd0080e7          	jalr	-560(ra) # 80001b14 <myproc>
    80002d4c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d4e:	05853903          	ld	s2,88(a0)
    80002d52:	0a893783          	ld	a5,168(s2)
    80002d56:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d5a:	37fd                	addiw	a5,a5,-1
    80002d5c:	4751                	li	a4,20
    80002d5e:	00f76f63          	bltu	a4,a5,80002d7c <syscall+0x44>
    80002d62:	00369713          	slli	a4,a3,0x3
    80002d66:	00005797          	auipc	a5,0x5
    80002d6a:	6a278793          	addi	a5,a5,1698 # 80008408 <syscalls>
    80002d6e:	97ba                	add	a5,a5,a4
    80002d70:	639c                	ld	a5,0(a5)
    80002d72:	c789                	beqz	a5,80002d7c <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d74:	9782                	jalr	a5
    80002d76:	06a93823          	sd	a0,112(s2)
    80002d7a:	a839                	j	80002d98 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d7c:	15848613          	addi	a2,s1,344
    80002d80:	588c                	lw	a1,48(s1)
    80002d82:	00005517          	auipc	a0,0x5
    80002d86:	64e50513          	addi	a0,a0,1614 # 800083d0 <states.1736+0x150>
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	804080e7          	jalr	-2044(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d92:	6cbc                	ld	a5,88(s1)
    80002d94:	577d                	li	a4,-1
    80002d96:	fbb8                	sd	a4,112(a5)
  }
}
    80002d98:	60e2                	ld	ra,24(sp)
    80002d9a:	6442                	ld	s0,16(sp)
    80002d9c:	64a2                	ld	s1,8(sp)
    80002d9e:	6902                	ld	s2,0(sp)
    80002da0:	6105                	addi	sp,sp,32
    80002da2:	8082                	ret

0000000080002da4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002da4:	1101                	addi	sp,sp,-32
    80002da6:	ec06                	sd	ra,24(sp)
    80002da8:	e822                	sd	s0,16(sp)
    80002daa:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dac:	fec40593          	addi	a1,s0,-20
    80002db0:	4501                	li	a0,0
    80002db2:	00000097          	auipc	ra,0x0
    80002db6:	f0e080e7          	jalr	-242(ra) # 80002cc0 <argint>
  exit(n);
    80002dba:	fec42503          	lw	a0,-20(s0)
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	59a080e7          	jalr	1434(ra) # 80002358 <exit>
  return 0;  // not reached
}
    80002dc6:	4501                	li	a0,0
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret

0000000080002dd0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dd0:	1141                	addi	sp,sp,-16
    80002dd2:	e406                	sd	ra,8(sp)
    80002dd4:	e022                	sd	s0,0(sp)
    80002dd6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	d3c080e7          	jalr	-708(ra) # 80001b14 <myproc>
}
    80002de0:	5908                	lw	a0,48(a0)
    80002de2:	60a2                	ld	ra,8(sp)
    80002de4:	6402                	ld	s0,0(sp)
    80002de6:	0141                	addi	sp,sp,16
    80002de8:	8082                	ret

0000000080002dea <sys_fork>:

uint64
sys_fork(void)
{
    80002dea:	1141                	addi	sp,sp,-16
    80002dec:	e406                	sd	ra,8(sp)
    80002dee:	e022                	sd	s0,0(sp)
    80002df0:	0800                	addi	s0,sp,16
  return fork();
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	144080e7          	jalr	324(ra) # 80001f36 <fork>
}
    80002dfa:	60a2                	ld	ra,8(sp)
    80002dfc:	6402                	ld	s0,0(sp)
    80002dfe:	0141                	addi	sp,sp,16
    80002e00:	8082                	ret

0000000080002e02 <sys_wait>:

uint64
sys_wait(void)
{
    80002e02:	1101                	addi	sp,sp,-32
    80002e04:	ec06                	sd	ra,24(sp)
    80002e06:	e822                	sd	s0,16(sp)
    80002e08:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e0a:	fe840593          	addi	a1,s0,-24
    80002e0e:	4501                	li	a0,0
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	ed0080e7          	jalr	-304(ra) # 80002ce0 <argaddr>
  return wait(p);
    80002e18:	fe843503          	ld	a0,-24(s0)
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	6e2080e7          	jalr	1762(ra) # 800024fe <wait>
}
    80002e24:	60e2                	ld	ra,24(sp)
    80002e26:	6442                	ld	s0,16(sp)
    80002e28:	6105                	addi	sp,sp,32
    80002e2a:	8082                	ret

0000000080002e2c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e2c:	7179                	addi	sp,sp,-48
    80002e2e:	f406                	sd	ra,40(sp)
    80002e30:	f022                	sd	s0,32(sp)
    80002e32:	ec26                	sd	s1,24(sp)
    80002e34:	1800                	addi	s0,sp,48
  int n;

  argint(0, &n);
    80002e36:	fdc40593          	addi	a1,s0,-36
    80002e3a:	4501                	li	a0,0
    80002e3c:	00000097          	auipc	ra,0x0
    80002e40:	e84080e7          	jalr	-380(ra) # 80002cc0 <argint>

  struct proc* p = myproc();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	cd0080e7          	jalr	-816(ra) # 80001b14 <myproc>
    80002e4c:	87aa                	mv	a5,a0

  uint64 prev_sz = p->sz;
    80002e4e:	6524                	ld	s1,72(a0)
  if (n > 0) {
    80002e50:	fdc42503          	lw	a0,-36(s0)
    80002e54:	00a05a63          	blez	a0,80002e68 <sys_sbrk+0x3c>
    p->sz += n;
    80002e58:	9526                	add	a0,a0,s1
    80002e5a:	e7a8                	sd	a0,72(a5)

    growproc(n);
  }
  
  return prev_sz;
}
    80002e5c:	8526                	mv	a0,s1
    80002e5e:	70a2                	ld	ra,40(sp)
    80002e60:	7402                	ld	s0,32(sp)
    80002e62:	64e2                	ld	s1,24(sp)
    80002e64:	6145                	addi	sp,sp,48
    80002e66:	8082                	ret
    growproc(n);
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	006080e7          	jalr	6(ra) # 80001e6e <growproc>
  return prev_sz;
    80002e70:	b7f5                	j	80002e5c <sys_sbrk+0x30>

0000000080002e72 <sys_sleep>:


uint64
sys_sleep(void)
{
    80002e72:	7139                	addi	sp,sp,-64
    80002e74:	fc06                	sd	ra,56(sp)
    80002e76:	f822                	sd	s0,48(sp)
    80002e78:	f426                	sd	s1,40(sp)
    80002e7a:	f04a                	sd	s2,32(sp)
    80002e7c:	ec4e                	sd	s3,24(sp)
    80002e7e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e80:	fcc40593          	addi	a1,s0,-52
    80002e84:	4501                	li	a0,0
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	e3a080e7          	jalr	-454(ra) # 80002cc0 <argint>
  acquire(&tickslock);
    80002e8e:	00014517          	auipc	a0,0x14
    80002e92:	ab250513          	addi	a0,a0,-1358 # 80016940 <tickslock>
    80002e96:	ffffe097          	auipc	ra,0xffffe
    80002e9a:	d54080e7          	jalr	-684(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002e9e:	00006917          	auipc	s2,0x6
    80002ea2:	a0292903          	lw	s2,-1534(s2) # 800088a0 <ticks>
  while(ticks - ticks0 < n){
    80002ea6:	fcc42783          	lw	a5,-52(s0)
    80002eaa:	cf9d                	beqz	a5,80002ee8 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eac:	00014997          	auipc	s3,0x14
    80002eb0:	a9498993          	addi	s3,s3,-1388 # 80016940 <tickslock>
    80002eb4:	00006497          	auipc	s1,0x6
    80002eb8:	9ec48493          	addi	s1,s1,-1556 # 800088a0 <ticks>
    if(killed(myproc())){
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	c58080e7          	jalr	-936(ra) # 80001b14 <myproc>
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	608080e7          	jalr	1544(ra) # 800024cc <killed>
    80002ecc:	ed15                	bnez	a0,80002f08 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ece:	85ce                	mv	a1,s3
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	352080e7          	jalr	850(ra) # 80002224 <sleep>
  while(ticks - ticks0 < n){
    80002eda:	409c                	lw	a5,0(s1)
    80002edc:	412787bb          	subw	a5,a5,s2
    80002ee0:	fcc42703          	lw	a4,-52(s0)
    80002ee4:	fce7ece3          	bltu	a5,a4,80002ebc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ee8:	00014517          	auipc	a0,0x14
    80002eec:	a5850513          	addi	a0,a0,-1448 # 80016940 <tickslock>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	dae080e7          	jalr	-594(ra) # 80000c9e <release>
  return 0;
    80002ef8:	4501                	li	a0,0
}
    80002efa:	70e2                	ld	ra,56(sp)
    80002efc:	7442                	ld	s0,48(sp)
    80002efe:	74a2                	ld	s1,40(sp)
    80002f00:	7902                	ld	s2,32(sp)
    80002f02:	69e2                	ld	s3,24(sp)
    80002f04:	6121                	addi	sp,sp,64
    80002f06:	8082                	ret
      release(&tickslock);
    80002f08:	00014517          	auipc	a0,0x14
    80002f0c:	a3850513          	addi	a0,a0,-1480 # 80016940 <tickslock>
    80002f10:	ffffe097          	auipc	ra,0xffffe
    80002f14:	d8e080e7          	jalr	-626(ra) # 80000c9e <release>
      return -1;
    80002f18:	557d                	li	a0,-1
    80002f1a:	b7c5                	j	80002efa <sys_sleep+0x88>

0000000080002f1c <sys_kill>:

uint64
sys_kill(void)
{
    80002f1c:	1101                	addi	sp,sp,-32
    80002f1e:	ec06                	sd	ra,24(sp)
    80002f20:	e822                	sd	s0,16(sp)
    80002f22:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f24:	fec40593          	addi	a1,s0,-20
    80002f28:	4501                	li	a0,0
    80002f2a:	00000097          	auipc	ra,0x0
    80002f2e:	d96080e7          	jalr	-618(ra) # 80002cc0 <argint>
  return kill(pid);
    80002f32:	fec42503          	lw	a0,-20(s0)
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	4f8080e7          	jalr	1272(ra) # 8000242e <kill>
}
    80002f3e:	60e2                	ld	ra,24(sp)
    80002f40:	6442                	ld	s0,16(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret

0000000080002f46 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f46:	1101                	addi	sp,sp,-32
    80002f48:	ec06                	sd	ra,24(sp)
    80002f4a:	e822                	sd	s0,16(sp)
    80002f4c:	e426                	sd	s1,8(sp)
    80002f4e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f50:	00014517          	auipc	a0,0x14
    80002f54:	9f050513          	addi	a0,a0,-1552 # 80016940 <tickslock>
    80002f58:	ffffe097          	auipc	ra,0xffffe
    80002f5c:	c92080e7          	jalr	-878(ra) # 80000bea <acquire>
  xticks = ticks;
    80002f60:	00006497          	auipc	s1,0x6
    80002f64:	9404a483          	lw	s1,-1728(s1) # 800088a0 <ticks>
  release(&tickslock);
    80002f68:	00014517          	auipc	a0,0x14
    80002f6c:	9d850513          	addi	a0,a0,-1576 # 80016940 <tickslock>
    80002f70:	ffffe097          	auipc	ra,0xffffe
    80002f74:	d2e080e7          	jalr	-722(ra) # 80000c9e <release>
  return xticks;
}
    80002f78:	02049513          	slli	a0,s1,0x20
    80002f7c:	9101                	srli	a0,a0,0x20
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	64a2                	ld	s1,8(sp)
    80002f84:	6105                	addi	sp,sp,32
    80002f86:	8082                	ret

0000000080002f88 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f88:	7179                	addi	sp,sp,-48
    80002f8a:	f406                	sd	ra,40(sp)
    80002f8c:	f022                	sd	s0,32(sp)
    80002f8e:	ec26                	sd	s1,24(sp)
    80002f90:	e84a                	sd	s2,16(sp)
    80002f92:	e44e                	sd	s3,8(sp)
    80002f94:	e052                	sd	s4,0(sp)
    80002f96:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f98:	00005597          	auipc	a1,0x5
    80002f9c:	52058593          	addi	a1,a1,1312 # 800084b8 <syscalls+0xb0>
    80002fa0:	00014517          	auipc	a0,0x14
    80002fa4:	9b850513          	addi	a0,a0,-1608 # 80016958 <bcache>
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	bb2080e7          	jalr	-1102(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fb0:	0001c797          	auipc	a5,0x1c
    80002fb4:	9a878793          	addi	a5,a5,-1624 # 8001e958 <bcache+0x8000>
    80002fb8:	0001c717          	auipc	a4,0x1c
    80002fbc:	c0870713          	addi	a4,a4,-1016 # 8001ebc0 <bcache+0x8268>
    80002fc0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fc4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc8:	00014497          	auipc	s1,0x14
    80002fcc:	9a848493          	addi	s1,s1,-1624 # 80016970 <bcache+0x18>
    b->next = bcache.head.next;
    80002fd0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fd2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fd4:	00005a17          	auipc	s4,0x5
    80002fd8:	4eca0a13          	addi	s4,s4,1260 # 800084c0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002fdc:	2b893783          	ld	a5,696(s2)
    80002fe0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fe2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fe6:	85d2                	mv	a1,s4
    80002fe8:	01048513          	addi	a0,s1,16
    80002fec:	00001097          	auipc	ra,0x1
    80002ff0:	4c4080e7          	jalr	1220(ra) # 800044b0 <initsleeplock>
    bcache.head.next->prev = b;
    80002ff4:	2b893783          	ld	a5,696(s2)
    80002ff8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ffa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ffe:	45848493          	addi	s1,s1,1112
    80003002:	fd349de3          	bne	s1,s3,80002fdc <binit+0x54>
  }
}
    80003006:	70a2                	ld	ra,40(sp)
    80003008:	7402                	ld	s0,32(sp)
    8000300a:	64e2                	ld	s1,24(sp)
    8000300c:	6942                	ld	s2,16(sp)
    8000300e:	69a2                	ld	s3,8(sp)
    80003010:	6a02                	ld	s4,0(sp)
    80003012:	6145                	addi	sp,sp,48
    80003014:	8082                	ret

0000000080003016 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003016:	7179                	addi	sp,sp,-48
    80003018:	f406                	sd	ra,40(sp)
    8000301a:	f022                	sd	s0,32(sp)
    8000301c:	ec26                	sd	s1,24(sp)
    8000301e:	e84a                	sd	s2,16(sp)
    80003020:	e44e                	sd	s3,8(sp)
    80003022:	1800                	addi	s0,sp,48
    80003024:	89aa                	mv	s3,a0
    80003026:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003028:	00014517          	auipc	a0,0x14
    8000302c:	93050513          	addi	a0,a0,-1744 # 80016958 <bcache>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	bba080e7          	jalr	-1094(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003038:	0001c497          	auipc	s1,0x1c
    8000303c:	bd84b483          	ld	s1,-1064(s1) # 8001ec10 <bcache+0x82b8>
    80003040:	0001c797          	auipc	a5,0x1c
    80003044:	b8078793          	addi	a5,a5,-1152 # 8001ebc0 <bcache+0x8268>
    80003048:	02f48f63          	beq	s1,a5,80003086 <bread+0x70>
    8000304c:	873e                	mv	a4,a5
    8000304e:	a021                	j	80003056 <bread+0x40>
    80003050:	68a4                	ld	s1,80(s1)
    80003052:	02e48a63          	beq	s1,a4,80003086 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003056:	449c                	lw	a5,8(s1)
    80003058:	ff379ce3          	bne	a5,s3,80003050 <bread+0x3a>
    8000305c:	44dc                	lw	a5,12(s1)
    8000305e:	ff2799e3          	bne	a5,s2,80003050 <bread+0x3a>
      b->refcnt++;
    80003062:	40bc                	lw	a5,64(s1)
    80003064:	2785                	addiw	a5,a5,1
    80003066:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003068:	00014517          	auipc	a0,0x14
    8000306c:	8f050513          	addi	a0,a0,-1808 # 80016958 <bcache>
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	c2e080e7          	jalr	-978(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003078:	01048513          	addi	a0,s1,16
    8000307c:	00001097          	auipc	ra,0x1
    80003080:	46e080e7          	jalr	1134(ra) # 800044ea <acquiresleep>
      return b;
    80003084:	a8b9                	j	800030e2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003086:	0001c497          	auipc	s1,0x1c
    8000308a:	b824b483          	ld	s1,-1150(s1) # 8001ec08 <bcache+0x82b0>
    8000308e:	0001c797          	auipc	a5,0x1c
    80003092:	b3278793          	addi	a5,a5,-1230 # 8001ebc0 <bcache+0x8268>
    80003096:	00f48863          	beq	s1,a5,800030a6 <bread+0x90>
    8000309a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000309c:	40bc                	lw	a5,64(s1)
    8000309e:	cf81                	beqz	a5,800030b6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030a0:	64a4                	ld	s1,72(s1)
    800030a2:	fee49de3          	bne	s1,a4,8000309c <bread+0x86>
  panic("bget: no buffers");
    800030a6:	00005517          	auipc	a0,0x5
    800030aa:	42250513          	addi	a0,a0,1058 # 800084c8 <syscalls+0xc0>
    800030ae:	ffffd097          	auipc	ra,0xffffd
    800030b2:	496080e7          	jalr	1174(ra) # 80000544 <panic>
      b->dev = dev;
    800030b6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030ba:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030be:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030c2:	4785                	li	a5,1
    800030c4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c6:	00014517          	auipc	a0,0x14
    800030ca:	89250513          	addi	a0,a0,-1902 # 80016958 <bcache>
    800030ce:	ffffe097          	auipc	ra,0xffffe
    800030d2:	bd0080e7          	jalr	-1072(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800030d6:	01048513          	addi	a0,s1,16
    800030da:	00001097          	auipc	ra,0x1
    800030de:	410080e7          	jalr	1040(ra) # 800044ea <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030e2:	409c                	lw	a5,0(s1)
    800030e4:	cb89                	beqz	a5,800030f6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030e6:	8526                	mv	a0,s1
    800030e8:	70a2                	ld	ra,40(sp)
    800030ea:	7402                	ld	s0,32(sp)
    800030ec:	64e2                	ld	s1,24(sp)
    800030ee:	6942                	ld	s2,16(sp)
    800030f0:	69a2                	ld	s3,8(sp)
    800030f2:	6145                	addi	sp,sp,48
    800030f4:	8082                	ret
    virtio_disk_rw(b, 0);
    800030f6:	4581                	li	a1,0
    800030f8:	8526                	mv	a0,s1
    800030fa:	00003097          	auipc	ra,0x3
    800030fe:	fde080e7          	jalr	-34(ra) # 800060d8 <virtio_disk_rw>
    b->valid = 1;
    80003102:	4785                	li	a5,1
    80003104:	c09c                	sw	a5,0(s1)
  return b;
    80003106:	b7c5                	j	800030e6 <bread+0xd0>

0000000080003108 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	1000                	addi	s0,sp,32
    80003112:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003114:	0541                	addi	a0,a0,16
    80003116:	00001097          	auipc	ra,0x1
    8000311a:	46e080e7          	jalr	1134(ra) # 80004584 <holdingsleep>
    8000311e:	cd01                	beqz	a0,80003136 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003120:	4585                	li	a1,1
    80003122:	8526                	mv	a0,s1
    80003124:	00003097          	auipc	ra,0x3
    80003128:	fb4080e7          	jalr	-76(ra) # 800060d8 <virtio_disk_rw>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6105                	addi	sp,sp,32
    80003134:	8082                	ret
    panic("bwrite");
    80003136:	00005517          	auipc	a0,0x5
    8000313a:	3aa50513          	addi	a0,a0,938 # 800084e0 <syscalls+0xd8>
    8000313e:	ffffd097          	auipc	ra,0xffffd
    80003142:	406080e7          	jalr	1030(ra) # 80000544 <panic>

0000000080003146 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	e04a                	sd	s2,0(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003154:	01050913          	addi	s2,a0,16
    80003158:	854a                	mv	a0,s2
    8000315a:	00001097          	auipc	ra,0x1
    8000315e:	42a080e7          	jalr	1066(ra) # 80004584 <holdingsleep>
    80003162:	c92d                	beqz	a0,800031d4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003164:	854a                	mv	a0,s2
    80003166:	00001097          	auipc	ra,0x1
    8000316a:	3da080e7          	jalr	986(ra) # 80004540 <releasesleep>

  acquire(&bcache.lock);
    8000316e:	00013517          	auipc	a0,0x13
    80003172:	7ea50513          	addi	a0,a0,2026 # 80016958 <bcache>
    80003176:	ffffe097          	auipc	ra,0xffffe
    8000317a:	a74080e7          	jalr	-1420(ra) # 80000bea <acquire>
  b->refcnt--;
    8000317e:	40bc                	lw	a5,64(s1)
    80003180:	37fd                	addiw	a5,a5,-1
    80003182:	0007871b          	sext.w	a4,a5
    80003186:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003188:	eb05                	bnez	a4,800031b8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000318a:	68bc                	ld	a5,80(s1)
    8000318c:	64b8                	ld	a4,72(s1)
    8000318e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003190:	64bc                	ld	a5,72(s1)
    80003192:	68b8                	ld	a4,80(s1)
    80003194:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003196:	0001b797          	auipc	a5,0x1b
    8000319a:	7c278793          	addi	a5,a5,1986 # 8001e958 <bcache+0x8000>
    8000319e:	2b87b703          	ld	a4,696(a5)
    800031a2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031a4:	0001c717          	auipc	a4,0x1c
    800031a8:	a1c70713          	addi	a4,a4,-1508 # 8001ebc0 <bcache+0x8268>
    800031ac:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031ae:	2b87b703          	ld	a4,696(a5)
    800031b2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031b4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031b8:	00013517          	auipc	a0,0x13
    800031bc:	7a050513          	addi	a0,a0,1952 # 80016958 <bcache>
    800031c0:	ffffe097          	auipc	ra,0xffffe
    800031c4:	ade080e7          	jalr	-1314(ra) # 80000c9e <release>
}
    800031c8:	60e2                	ld	ra,24(sp)
    800031ca:	6442                	ld	s0,16(sp)
    800031cc:	64a2                	ld	s1,8(sp)
    800031ce:	6902                	ld	s2,0(sp)
    800031d0:	6105                	addi	sp,sp,32
    800031d2:	8082                	ret
    panic("brelse");
    800031d4:	00005517          	auipc	a0,0x5
    800031d8:	31450513          	addi	a0,a0,788 # 800084e8 <syscalls+0xe0>
    800031dc:	ffffd097          	auipc	ra,0xffffd
    800031e0:	368080e7          	jalr	872(ra) # 80000544 <panic>

00000000800031e4 <bpin>:

void
bpin(struct buf *b) {
    800031e4:	1101                	addi	sp,sp,-32
    800031e6:	ec06                	sd	ra,24(sp)
    800031e8:	e822                	sd	s0,16(sp)
    800031ea:	e426                	sd	s1,8(sp)
    800031ec:	1000                	addi	s0,sp,32
    800031ee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f0:	00013517          	auipc	a0,0x13
    800031f4:	76850513          	addi	a0,a0,1896 # 80016958 <bcache>
    800031f8:	ffffe097          	auipc	ra,0xffffe
    800031fc:	9f2080e7          	jalr	-1550(ra) # 80000bea <acquire>
  b->refcnt++;
    80003200:	40bc                	lw	a5,64(s1)
    80003202:	2785                	addiw	a5,a5,1
    80003204:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003206:	00013517          	auipc	a0,0x13
    8000320a:	75250513          	addi	a0,a0,1874 # 80016958 <bcache>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	a90080e7          	jalr	-1392(ra) # 80000c9e <release>
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret

0000000080003220 <bunpin>:

void
bunpin(struct buf *b) {
    80003220:	1101                	addi	sp,sp,-32
    80003222:	ec06                	sd	ra,24(sp)
    80003224:	e822                	sd	s0,16(sp)
    80003226:	e426                	sd	s1,8(sp)
    80003228:	1000                	addi	s0,sp,32
    8000322a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000322c:	00013517          	auipc	a0,0x13
    80003230:	72c50513          	addi	a0,a0,1836 # 80016958 <bcache>
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	9b6080e7          	jalr	-1610(ra) # 80000bea <acquire>
  b->refcnt--;
    8000323c:	40bc                	lw	a5,64(s1)
    8000323e:	37fd                	addiw	a5,a5,-1
    80003240:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003242:	00013517          	auipc	a0,0x13
    80003246:	71650513          	addi	a0,a0,1814 # 80016958 <bcache>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	a54080e7          	jalr	-1452(ra) # 80000c9e <release>
}
    80003252:	60e2                	ld	ra,24(sp)
    80003254:	6442                	ld	s0,16(sp)
    80003256:	64a2                	ld	s1,8(sp)
    80003258:	6105                	addi	sp,sp,32
    8000325a:	8082                	ret

000000008000325c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000325c:	1101                	addi	sp,sp,-32
    8000325e:	ec06                	sd	ra,24(sp)
    80003260:	e822                	sd	s0,16(sp)
    80003262:	e426                	sd	s1,8(sp)
    80003264:	e04a                	sd	s2,0(sp)
    80003266:	1000                	addi	s0,sp,32
    80003268:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000326a:	00d5d59b          	srliw	a1,a1,0xd
    8000326e:	0001c797          	auipc	a5,0x1c
    80003272:	dc67a783          	lw	a5,-570(a5) # 8001f034 <sb+0x1c>
    80003276:	9dbd                	addw	a1,a1,a5
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	d9e080e7          	jalr	-610(ra) # 80003016 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003280:	0074f713          	andi	a4,s1,7
    80003284:	4785                	li	a5,1
    80003286:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000328a:	14ce                	slli	s1,s1,0x33
    8000328c:	90d9                	srli	s1,s1,0x36
    8000328e:	00950733          	add	a4,a0,s1
    80003292:	05874703          	lbu	a4,88(a4)
    80003296:	00e7f6b3          	and	a3,a5,a4
    8000329a:	c69d                	beqz	a3,800032c8 <bfree+0x6c>
    8000329c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000329e:	94aa                	add	s1,s1,a0
    800032a0:	fff7c793          	not	a5,a5
    800032a4:	8ff9                	and	a5,a5,a4
    800032a6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032aa:	00001097          	auipc	ra,0x1
    800032ae:	120080e7          	jalr	288(ra) # 800043ca <log_write>
  brelse(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	e92080e7          	jalr	-366(ra) # 80003146 <brelse>
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	64a2                	ld	s1,8(sp)
    800032c2:	6902                	ld	s2,0(sp)
    800032c4:	6105                	addi	sp,sp,32
    800032c6:	8082                	ret
    panic("freeing free block");
    800032c8:	00005517          	auipc	a0,0x5
    800032cc:	22850513          	addi	a0,a0,552 # 800084f0 <syscalls+0xe8>
    800032d0:	ffffd097          	auipc	ra,0xffffd
    800032d4:	274080e7          	jalr	628(ra) # 80000544 <panic>

00000000800032d8 <balloc>:
{
    800032d8:	711d                	addi	sp,sp,-96
    800032da:	ec86                	sd	ra,88(sp)
    800032dc:	e8a2                	sd	s0,80(sp)
    800032de:	e4a6                	sd	s1,72(sp)
    800032e0:	e0ca                	sd	s2,64(sp)
    800032e2:	fc4e                	sd	s3,56(sp)
    800032e4:	f852                	sd	s4,48(sp)
    800032e6:	f456                	sd	s5,40(sp)
    800032e8:	f05a                	sd	s6,32(sp)
    800032ea:	ec5e                	sd	s7,24(sp)
    800032ec:	e862                	sd	s8,16(sp)
    800032ee:	e466                	sd	s9,8(sp)
    800032f0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032f2:	0001c797          	auipc	a5,0x1c
    800032f6:	d2a7a783          	lw	a5,-726(a5) # 8001f01c <sb+0x4>
    800032fa:	10078163          	beqz	a5,800033fc <balloc+0x124>
    800032fe:	8baa                	mv	s7,a0
    80003300:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003302:	0001cb17          	auipc	s6,0x1c
    80003306:	d16b0b13          	addi	s6,s6,-746 # 8001f018 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000330c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003310:	6c89                	lui	s9,0x2
    80003312:	a061                	j	8000339a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003314:	974a                	add	a4,a4,s2
    80003316:	8fd5                	or	a5,a5,a3
    80003318:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000331c:	854a                	mv	a0,s2
    8000331e:	00001097          	auipc	ra,0x1
    80003322:	0ac080e7          	jalr	172(ra) # 800043ca <log_write>
        brelse(bp);
    80003326:	854a                	mv	a0,s2
    80003328:	00000097          	auipc	ra,0x0
    8000332c:	e1e080e7          	jalr	-482(ra) # 80003146 <brelse>
  bp = bread(dev, bno);
    80003330:	85a6                	mv	a1,s1
    80003332:	855e                	mv	a0,s7
    80003334:	00000097          	auipc	ra,0x0
    80003338:	ce2080e7          	jalr	-798(ra) # 80003016 <bread>
    8000333c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000333e:	40000613          	li	a2,1024
    80003342:	4581                	li	a1,0
    80003344:	05850513          	addi	a0,a0,88
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	99e080e7          	jalr	-1634(ra) # 80000ce6 <memset>
  log_write(bp);
    80003350:	854a                	mv	a0,s2
    80003352:	00001097          	auipc	ra,0x1
    80003356:	078080e7          	jalr	120(ra) # 800043ca <log_write>
  brelse(bp);
    8000335a:	854a                	mv	a0,s2
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	dea080e7          	jalr	-534(ra) # 80003146 <brelse>
}
    80003364:	8526                	mv	a0,s1
    80003366:	60e6                	ld	ra,88(sp)
    80003368:	6446                	ld	s0,80(sp)
    8000336a:	64a6                	ld	s1,72(sp)
    8000336c:	6906                	ld	s2,64(sp)
    8000336e:	79e2                	ld	s3,56(sp)
    80003370:	7a42                	ld	s4,48(sp)
    80003372:	7aa2                	ld	s5,40(sp)
    80003374:	7b02                	ld	s6,32(sp)
    80003376:	6be2                	ld	s7,24(sp)
    80003378:	6c42                	ld	s8,16(sp)
    8000337a:	6ca2                	ld	s9,8(sp)
    8000337c:	6125                	addi	sp,sp,96
    8000337e:	8082                	ret
    brelse(bp);
    80003380:	854a                	mv	a0,s2
    80003382:	00000097          	auipc	ra,0x0
    80003386:	dc4080e7          	jalr	-572(ra) # 80003146 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000338a:	015c87bb          	addw	a5,s9,s5
    8000338e:	00078a9b          	sext.w	s5,a5
    80003392:	004b2703          	lw	a4,4(s6)
    80003396:	06eaf363          	bgeu	s5,a4,800033fc <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000339a:	41fad79b          	sraiw	a5,s5,0x1f
    8000339e:	0137d79b          	srliw	a5,a5,0x13
    800033a2:	015787bb          	addw	a5,a5,s5
    800033a6:	40d7d79b          	sraiw	a5,a5,0xd
    800033aa:	01cb2583          	lw	a1,28(s6)
    800033ae:	9dbd                	addw	a1,a1,a5
    800033b0:	855e                	mv	a0,s7
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	c64080e7          	jalr	-924(ra) # 80003016 <bread>
    800033ba:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033bc:	004b2503          	lw	a0,4(s6)
    800033c0:	000a849b          	sext.w	s1,s5
    800033c4:	8662                	mv	a2,s8
    800033c6:	faa4fde3          	bgeu	s1,a0,80003380 <balloc+0xa8>
      m = 1 << (bi % 8);
    800033ca:	41f6579b          	sraiw	a5,a2,0x1f
    800033ce:	01d7d69b          	srliw	a3,a5,0x1d
    800033d2:	00c6873b          	addw	a4,a3,a2
    800033d6:	00777793          	andi	a5,a4,7
    800033da:	9f95                	subw	a5,a5,a3
    800033dc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033e0:	4037571b          	sraiw	a4,a4,0x3
    800033e4:	00e906b3          	add	a3,s2,a4
    800033e8:	0586c683          	lbu	a3,88(a3)
    800033ec:	00d7f5b3          	and	a1,a5,a3
    800033f0:	d195                	beqz	a1,80003314 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f2:	2605                	addiw	a2,a2,1
    800033f4:	2485                	addiw	s1,s1,1
    800033f6:	fd4618e3          	bne	a2,s4,800033c6 <balloc+0xee>
    800033fa:	b759                	j	80003380 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800033fc:	00005517          	auipc	a0,0x5
    80003400:	10c50513          	addi	a0,a0,268 # 80008508 <syscalls+0x100>
    80003404:	ffffd097          	auipc	ra,0xffffd
    80003408:	18a080e7          	jalr	394(ra) # 8000058e <printf>
  return 0;
    8000340c:	4481                	li	s1,0
    8000340e:	bf99                	j	80003364 <balloc+0x8c>

0000000080003410 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003410:	7179                	addi	sp,sp,-48
    80003412:	f406                	sd	ra,40(sp)
    80003414:	f022                	sd	s0,32(sp)
    80003416:	ec26                	sd	s1,24(sp)
    80003418:	e84a                	sd	s2,16(sp)
    8000341a:	e44e                	sd	s3,8(sp)
    8000341c:	e052                	sd	s4,0(sp)
    8000341e:	1800                	addi	s0,sp,48
    80003420:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003422:	47ad                	li	a5,11
    80003424:	02b7e763          	bltu	a5,a1,80003452 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003428:	02059493          	slli	s1,a1,0x20
    8000342c:	9081                	srli	s1,s1,0x20
    8000342e:	048a                	slli	s1,s1,0x2
    80003430:	94aa                	add	s1,s1,a0
    80003432:	0504a903          	lw	s2,80(s1)
    80003436:	06091e63          	bnez	s2,800034b2 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000343a:	4108                	lw	a0,0(a0)
    8000343c:	00000097          	auipc	ra,0x0
    80003440:	e9c080e7          	jalr	-356(ra) # 800032d8 <balloc>
    80003444:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003448:	06090563          	beqz	s2,800034b2 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000344c:	0524a823          	sw	s2,80(s1)
    80003450:	a08d                	j	800034b2 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003452:	ff45849b          	addiw	s1,a1,-12
    80003456:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000345a:	0ff00793          	li	a5,255
    8000345e:	08e7e563          	bltu	a5,a4,800034e8 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003462:	08052903          	lw	s2,128(a0)
    80003466:	00091d63          	bnez	s2,80003480 <bmap+0x70>
      addr = balloc(ip->dev);
    8000346a:	4108                	lw	a0,0(a0)
    8000346c:	00000097          	auipc	ra,0x0
    80003470:	e6c080e7          	jalr	-404(ra) # 800032d8 <balloc>
    80003474:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003478:	02090d63          	beqz	s2,800034b2 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000347c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003480:	85ca                	mv	a1,s2
    80003482:	0009a503          	lw	a0,0(s3)
    80003486:	00000097          	auipc	ra,0x0
    8000348a:	b90080e7          	jalr	-1136(ra) # 80003016 <bread>
    8000348e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003490:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003494:	02049593          	slli	a1,s1,0x20
    80003498:	9181                	srli	a1,a1,0x20
    8000349a:	058a                	slli	a1,a1,0x2
    8000349c:	00b784b3          	add	s1,a5,a1
    800034a0:	0004a903          	lw	s2,0(s1)
    800034a4:	02090063          	beqz	s2,800034c4 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034a8:	8552                	mv	a0,s4
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	c9c080e7          	jalr	-868(ra) # 80003146 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800034b2:	854a                	mv	a0,s2
    800034b4:	70a2                	ld	ra,40(sp)
    800034b6:	7402                	ld	s0,32(sp)
    800034b8:	64e2                	ld	s1,24(sp)
    800034ba:	6942                	ld	s2,16(sp)
    800034bc:	69a2                	ld	s3,8(sp)
    800034be:	6a02                	ld	s4,0(sp)
    800034c0:	6145                	addi	sp,sp,48
    800034c2:	8082                	ret
      addr = balloc(ip->dev);
    800034c4:	0009a503          	lw	a0,0(s3)
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	e10080e7          	jalr	-496(ra) # 800032d8 <balloc>
    800034d0:	0005091b          	sext.w	s2,a0
      if(addr){
    800034d4:	fc090ae3          	beqz	s2,800034a8 <bmap+0x98>
        a[bn] = addr;
    800034d8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800034dc:	8552                	mv	a0,s4
    800034de:	00001097          	auipc	ra,0x1
    800034e2:	eec080e7          	jalr	-276(ra) # 800043ca <log_write>
    800034e6:	b7c9                	j	800034a8 <bmap+0x98>
  panic("bmap: out of range");
    800034e8:	00005517          	auipc	a0,0x5
    800034ec:	03850513          	addi	a0,a0,56 # 80008520 <syscalls+0x118>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	054080e7          	jalr	84(ra) # 80000544 <panic>

00000000800034f8 <iget>:
{
    800034f8:	7179                	addi	sp,sp,-48
    800034fa:	f406                	sd	ra,40(sp)
    800034fc:	f022                	sd	s0,32(sp)
    800034fe:	ec26                	sd	s1,24(sp)
    80003500:	e84a                	sd	s2,16(sp)
    80003502:	e44e                	sd	s3,8(sp)
    80003504:	e052                	sd	s4,0(sp)
    80003506:	1800                	addi	s0,sp,48
    80003508:	89aa                	mv	s3,a0
    8000350a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000350c:	0001c517          	auipc	a0,0x1c
    80003510:	b2c50513          	addi	a0,a0,-1236 # 8001f038 <itable>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	6d6080e7          	jalr	1750(ra) # 80000bea <acquire>
  empty = 0;
    8000351c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000351e:	0001c497          	auipc	s1,0x1c
    80003522:	b3248493          	addi	s1,s1,-1230 # 8001f050 <itable+0x18>
    80003526:	0001d697          	auipc	a3,0x1d
    8000352a:	5ba68693          	addi	a3,a3,1466 # 80020ae0 <log>
    8000352e:	a039                	j	8000353c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003530:	02090b63          	beqz	s2,80003566 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003534:	08848493          	addi	s1,s1,136
    80003538:	02d48a63          	beq	s1,a3,8000356c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000353c:	449c                	lw	a5,8(s1)
    8000353e:	fef059e3          	blez	a5,80003530 <iget+0x38>
    80003542:	4098                	lw	a4,0(s1)
    80003544:	ff3716e3          	bne	a4,s3,80003530 <iget+0x38>
    80003548:	40d8                	lw	a4,4(s1)
    8000354a:	ff4713e3          	bne	a4,s4,80003530 <iget+0x38>
      ip->ref++;
    8000354e:	2785                	addiw	a5,a5,1
    80003550:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003552:	0001c517          	auipc	a0,0x1c
    80003556:	ae650513          	addi	a0,a0,-1306 # 8001f038 <itable>
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	744080e7          	jalr	1860(ra) # 80000c9e <release>
      return ip;
    80003562:	8926                	mv	s2,s1
    80003564:	a03d                	j	80003592 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003566:	f7f9                	bnez	a5,80003534 <iget+0x3c>
    80003568:	8926                	mv	s2,s1
    8000356a:	b7e9                	j	80003534 <iget+0x3c>
  if(empty == 0)
    8000356c:	02090c63          	beqz	s2,800035a4 <iget+0xac>
  ip->dev = dev;
    80003570:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003574:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003578:	4785                	li	a5,1
    8000357a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000357e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003582:	0001c517          	auipc	a0,0x1c
    80003586:	ab650513          	addi	a0,a0,-1354 # 8001f038 <itable>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	714080e7          	jalr	1812(ra) # 80000c9e <release>
}
    80003592:	854a                	mv	a0,s2
    80003594:	70a2                	ld	ra,40(sp)
    80003596:	7402                	ld	s0,32(sp)
    80003598:	64e2                	ld	s1,24(sp)
    8000359a:	6942                	ld	s2,16(sp)
    8000359c:	69a2                	ld	s3,8(sp)
    8000359e:	6a02                	ld	s4,0(sp)
    800035a0:	6145                	addi	sp,sp,48
    800035a2:	8082                	ret
    panic("iget: no inodes");
    800035a4:	00005517          	auipc	a0,0x5
    800035a8:	f9450513          	addi	a0,a0,-108 # 80008538 <syscalls+0x130>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	f98080e7          	jalr	-104(ra) # 80000544 <panic>

00000000800035b4 <fsinit>:
fsinit(int dev) {
    800035b4:	7179                	addi	sp,sp,-48
    800035b6:	f406                	sd	ra,40(sp)
    800035b8:	f022                	sd	s0,32(sp)
    800035ba:	ec26                	sd	s1,24(sp)
    800035bc:	e84a                	sd	s2,16(sp)
    800035be:	e44e                	sd	s3,8(sp)
    800035c0:	1800                	addi	s0,sp,48
    800035c2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035c4:	4585                	li	a1,1
    800035c6:	00000097          	auipc	ra,0x0
    800035ca:	a50080e7          	jalr	-1456(ra) # 80003016 <bread>
    800035ce:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035d0:	0001c997          	auipc	s3,0x1c
    800035d4:	a4898993          	addi	s3,s3,-1464 # 8001f018 <sb>
    800035d8:	02000613          	li	a2,32
    800035dc:	05850593          	addi	a1,a0,88
    800035e0:	854e                	mv	a0,s3
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	764080e7          	jalr	1892(ra) # 80000d46 <memmove>
  brelse(bp);
    800035ea:	8526                	mv	a0,s1
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	b5a080e7          	jalr	-1190(ra) # 80003146 <brelse>
  if(sb.magic != FSMAGIC)
    800035f4:	0009a703          	lw	a4,0(s3)
    800035f8:	102037b7          	lui	a5,0x10203
    800035fc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003600:	02f71263          	bne	a4,a5,80003624 <fsinit+0x70>
  initlog(dev, &sb);
    80003604:	0001c597          	auipc	a1,0x1c
    80003608:	a1458593          	addi	a1,a1,-1516 # 8001f018 <sb>
    8000360c:	854a                	mv	a0,s2
    8000360e:	00001097          	auipc	ra,0x1
    80003612:	b40080e7          	jalr	-1216(ra) # 8000414e <initlog>
}
    80003616:	70a2                	ld	ra,40(sp)
    80003618:	7402                	ld	s0,32(sp)
    8000361a:	64e2                	ld	s1,24(sp)
    8000361c:	6942                	ld	s2,16(sp)
    8000361e:	69a2                	ld	s3,8(sp)
    80003620:	6145                	addi	sp,sp,48
    80003622:	8082                	ret
    panic("invalid file system");
    80003624:	00005517          	auipc	a0,0x5
    80003628:	f2450513          	addi	a0,a0,-220 # 80008548 <syscalls+0x140>
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	f18080e7          	jalr	-232(ra) # 80000544 <panic>

0000000080003634 <iinit>:
{
    80003634:	7179                	addi	sp,sp,-48
    80003636:	f406                	sd	ra,40(sp)
    80003638:	f022                	sd	s0,32(sp)
    8000363a:	ec26                	sd	s1,24(sp)
    8000363c:	e84a                	sd	s2,16(sp)
    8000363e:	e44e                	sd	s3,8(sp)
    80003640:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003642:	00005597          	auipc	a1,0x5
    80003646:	f1e58593          	addi	a1,a1,-226 # 80008560 <syscalls+0x158>
    8000364a:	0001c517          	auipc	a0,0x1c
    8000364e:	9ee50513          	addi	a0,a0,-1554 # 8001f038 <itable>
    80003652:	ffffd097          	auipc	ra,0xffffd
    80003656:	508080e7          	jalr	1288(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    8000365a:	0001c497          	auipc	s1,0x1c
    8000365e:	a0648493          	addi	s1,s1,-1530 # 8001f060 <itable+0x28>
    80003662:	0001d997          	auipc	s3,0x1d
    80003666:	48e98993          	addi	s3,s3,1166 # 80020af0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000366a:	00005917          	auipc	s2,0x5
    8000366e:	efe90913          	addi	s2,s2,-258 # 80008568 <syscalls+0x160>
    80003672:	85ca                	mv	a1,s2
    80003674:	8526                	mv	a0,s1
    80003676:	00001097          	auipc	ra,0x1
    8000367a:	e3a080e7          	jalr	-454(ra) # 800044b0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000367e:	08848493          	addi	s1,s1,136
    80003682:	ff3498e3          	bne	s1,s3,80003672 <iinit+0x3e>
}
    80003686:	70a2                	ld	ra,40(sp)
    80003688:	7402                	ld	s0,32(sp)
    8000368a:	64e2                	ld	s1,24(sp)
    8000368c:	6942                	ld	s2,16(sp)
    8000368e:	69a2                	ld	s3,8(sp)
    80003690:	6145                	addi	sp,sp,48
    80003692:	8082                	ret

0000000080003694 <ialloc>:
{
    80003694:	715d                	addi	sp,sp,-80
    80003696:	e486                	sd	ra,72(sp)
    80003698:	e0a2                	sd	s0,64(sp)
    8000369a:	fc26                	sd	s1,56(sp)
    8000369c:	f84a                	sd	s2,48(sp)
    8000369e:	f44e                	sd	s3,40(sp)
    800036a0:	f052                	sd	s4,32(sp)
    800036a2:	ec56                	sd	s5,24(sp)
    800036a4:	e85a                	sd	s6,16(sp)
    800036a6:	e45e                	sd	s7,8(sp)
    800036a8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036aa:	0001c717          	auipc	a4,0x1c
    800036ae:	97a72703          	lw	a4,-1670(a4) # 8001f024 <sb+0xc>
    800036b2:	4785                	li	a5,1
    800036b4:	04e7fa63          	bgeu	a5,a4,80003708 <ialloc+0x74>
    800036b8:	8aaa                	mv	s5,a0
    800036ba:	8bae                	mv	s7,a1
    800036bc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036be:	0001ca17          	auipc	s4,0x1c
    800036c2:	95aa0a13          	addi	s4,s4,-1702 # 8001f018 <sb>
    800036c6:	00048b1b          	sext.w	s6,s1
    800036ca:	0044d593          	srli	a1,s1,0x4
    800036ce:	018a2783          	lw	a5,24(s4)
    800036d2:	9dbd                	addw	a1,a1,a5
    800036d4:	8556                	mv	a0,s5
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	940080e7          	jalr	-1728(ra) # 80003016 <bread>
    800036de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036e0:	05850993          	addi	s3,a0,88
    800036e4:	00f4f793          	andi	a5,s1,15
    800036e8:	079a                	slli	a5,a5,0x6
    800036ea:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036ec:	00099783          	lh	a5,0(s3)
    800036f0:	c3a1                	beqz	a5,80003730 <ialloc+0x9c>
    brelse(bp);
    800036f2:	00000097          	auipc	ra,0x0
    800036f6:	a54080e7          	jalr	-1452(ra) # 80003146 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036fa:	0485                	addi	s1,s1,1
    800036fc:	00ca2703          	lw	a4,12(s4)
    80003700:	0004879b          	sext.w	a5,s1
    80003704:	fce7e1e3          	bltu	a5,a4,800036c6 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	e6850513          	addi	a0,a0,-408 # 80008570 <syscalls+0x168>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e7e080e7          	jalr	-386(ra) # 8000058e <printf>
  return 0;
    80003718:	4501                	li	a0,0
}
    8000371a:	60a6                	ld	ra,72(sp)
    8000371c:	6406                	ld	s0,64(sp)
    8000371e:	74e2                	ld	s1,56(sp)
    80003720:	7942                	ld	s2,48(sp)
    80003722:	79a2                	ld	s3,40(sp)
    80003724:	7a02                	ld	s4,32(sp)
    80003726:	6ae2                	ld	s5,24(sp)
    80003728:	6b42                	ld	s6,16(sp)
    8000372a:	6ba2                	ld	s7,8(sp)
    8000372c:	6161                	addi	sp,sp,80
    8000372e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003730:	04000613          	li	a2,64
    80003734:	4581                	li	a1,0
    80003736:	854e                	mv	a0,s3
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	5ae080e7          	jalr	1454(ra) # 80000ce6 <memset>
      dip->type = type;
    80003740:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003744:	854a                	mv	a0,s2
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	c84080e7          	jalr	-892(ra) # 800043ca <log_write>
      brelse(bp);
    8000374e:	854a                	mv	a0,s2
    80003750:	00000097          	auipc	ra,0x0
    80003754:	9f6080e7          	jalr	-1546(ra) # 80003146 <brelse>
      return iget(dev, inum);
    80003758:	85da                	mv	a1,s6
    8000375a:	8556                	mv	a0,s5
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	d9c080e7          	jalr	-612(ra) # 800034f8 <iget>
    80003764:	bf5d                	j	8000371a <ialloc+0x86>

0000000080003766 <iupdate>:
{
    80003766:	1101                	addi	sp,sp,-32
    80003768:	ec06                	sd	ra,24(sp)
    8000376a:	e822                	sd	s0,16(sp)
    8000376c:	e426                	sd	s1,8(sp)
    8000376e:	e04a                	sd	s2,0(sp)
    80003770:	1000                	addi	s0,sp,32
    80003772:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003774:	415c                	lw	a5,4(a0)
    80003776:	0047d79b          	srliw	a5,a5,0x4
    8000377a:	0001c597          	auipc	a1,0x1c
    8000377e:	8b65a583          	lw	a1,-1866(a1) # 8001f030 <sb+0x18>
    80003782:	9dbd                	addw	a1,a1,a5
    80003784:	4108                	lw	a0,0(a0)
    80003786:	00000097          	auipc	ra,0x0
    8000378a:	890080e7          	jalr	-1904(ra) # 80003016 <bread>
    8000378e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003790:	05850793          	addi	a5,a0,88
    80003794:	40c8                	lw	a0,4(s1)
    80003796:	893d                	andi	a0,a0,15
    80003798:	051a                	slli	a0,a0,0x6
    8000379a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000379c:	04449703          	lh	a4,68(s1)
    800037a0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037a4:	04649703          	lh	a4,70(s1)
    800037a8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037ac:	04849703          	lh	a4,72(s1)
    800037b0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037b4:	04a49703          	lh	a4,74(s1)
    800037b8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037bc:	44f8                	lw	a4,76(s1)
    800037be:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037c0:	03400613          	li	a2,52
    800037c4:	05048593          	addi	a1,s1,80
    800037c8:	0531                	addi	a0,a0,12
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	57c080e7          	jalr	1404(ra) # 80000d46 <memmove>
  log_write(bp);
    800037d2:	854a                	mv	a0,s2
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	bf6080e7          	jalr	-1034(ra) # 800043ca <log_write>
  brelse(bp);
    800037dc:	854a                	mv	a0,s2
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	968080e7          	jalr	-1688(ra) # 80003146 <brelse>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret

00000000800037f2 <idup>:
{
    800037f2:	1101                	addi	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	e426                	sd	s1,8(sp)
    800037fa:	1000                	addi	s0,sp,32
    800037fc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037fe:	0001c517          	auipc	a0,0x1c
    80003802:	83a50513          	addi	a0,a0,-1990 # 8001f038 <itable>
    80003806:	ffffd097          	auipc	ra,0xffffd
    8000380a:	3e4080e7          	jalr	996(ra) # 80000bea <acquire>
  ip->ref++;
    8000380e:	449c                	lw	a5,8(s1)
    80003810:	2785                	addiw	a5,a5,1
    80003812:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	82450513          	addi	a0,a0,-2012 # 8001f038 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	482080e7          	jalr	1154(ra) # 80000c9e <release>
}
    80003824:	8526                	mv	a0,s1
    80003826:	60e2                	ld	ra,24(sp)
    80003828:	6442                	ld	s0,16(sp)
    8000382a:	64a2                	ld	s1,8(sp)
    8000382c:	6105                	addi	sp,sp,32
    8000382e:	8082                	ret

0000000080003830 <ilock>:
{
    80003830:	1101                	addi	sp,sp,-32
    80003832:	ec06                	sd	ra,24(sp)
    80003834:	e822                	sd	s0,16(sp)
    80003836:	e426                	sd	s1,8(sp)
    80003838:	e04a                	sd	s2,0(sp)
    8000383a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000383c:	c115                	beqz	a0,80003860 <ilock+0x30>
    8000383e:	84aa                	mv	s1,a0
    80003840:	451c                	lw	a5,8(a0)
    80003842:	00f05f63          	blez	a5,80003860 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003846:	0541                	addi	a0,a0,16
    80003848:	00001097          	auipc	ra,0x1
    8000384c:	ca2080e7          	jalr	-862(ra) # 800044ea <acquiresleep>
  if(ip->valid == 0){
    80003850:	40bc                	lw	a5,64(s1)
    80003852:	cf99                	beqz	a5,80003870 <ilock+0x40>
}
    80003854:	60e2                	ld	ra,24(sp)
    80003856:	6442                	ld	s0,16(sp)
    80003858:	64a2                	ld	s1,8(sp)
    8000385a:	6902                	ld	s2,0(sp)
    8000385c:	6105                	addi	sp,sp,32
    8000385e:	8082                	ret
    panic("ilock");
    80003860:	00005517          	auipc	a0,0x5
    80003864:	d2850513          	addi	a0,a0,-728 # 80008588 <syscalls+0x180>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	cdc080e7          	jalr	-804(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003870:	40dc                	lw	a5,4(s1)
    80003872:	0047d79b          	srliw	a5,a5,0x4
    80003876:	0001b597          	auipc	a1,0x1b
    8000387a:	7ba5a583          	lw	a1,1978(a1) # 8001f030 <sb+0x18>
    8000387e:	9dbd                	addw	a1,a1,a5
    80003880:	4088                	lw	a0,0(s1)
    80003882:	fffff097          	auipc	ra,0xfffff
    80003886:	794080e7          	jalr	1940(ra) # 80003016 <bread>
    8000388a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000388c:	05850593          	addi	a1,a0,88
    80003890:	40dc                	lw	a5,4(s1)
    80003892:	8bbd                	andi	a5,a5,15
    80003894:	079a                	slli	a5,a5,0x6
    80003896:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003898:	00059783          	lh	a5,0(a1)
    8000389c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038a0:	00259783          	lh	a5,2(a1)
    800038a4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038a8:	00459783          	lh	a5,4(a1)
    800038ac:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038b0:	00659783          	lh	a5,6(a1)
    800038b4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038b8:	459c                	lw	a5,8(a1)
    800038ba:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038bc:	03400613          	li	a2,52
    800038c0:	05b1                	addi	a1,a1,12
    800038c2:	05048513          	addi	a0,s1,80
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	480080e7          	jalr	1152(ra) # 80000d46 <memmove>
    brelse(bp);
    800038ce:	854a                	mv	a0,s2
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	876080e7          	jalr	-1930(ra) # 80003146 <brelse>
    ip->valid = 1;
    800038d8:	4785                	li	a5,1
    800038da:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038dc:	04449783          	lh	a5,68(s1)
    800038e0:	fbb5                	bnez	a5,80003854 <ilock+0x24>
      panic("ilock: no type");
    800038e2:	00005517          	auipc	a0,0x5
    800038e6:	cae50513          	addi	a0,a0,-850 # 80008590 <syscalls+0x188>
    800038ea:	ffffd097          	auipc	ra,0xffffd
    800038ee:	c5a080e7          	jalr	-934(ra) # 80000544 <panic>

00000000800038f2 <iunlock>:
{
    800038f2:	1101                	addi	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	e04a                	sd	s2,0(sp)
    800038fc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038fe:	c905                	beqz	a0,8000392e <iunlock+0x3c>
    80003900:	84aa                	mv	s1,a0
    80003902:	01050913          	addi	s2,a0,16
    80003906:	854a                	mv	a0,s2
    80003908:	00001097          	auipc	ra,0x1
    8000390c:	c7c080e7          	jalr	-900(ra) # 80004584 <holdingsleep>
    80003910:	cd19                	beqz	a0,8000392e <iunlock+0x3c>
    80003912:	449c                	lw	a5,8(s1)
    80003914:	00f05d63          	blez	a5,8000392e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003918:	854a                	mv	a0,s2
    8000391a:	00001097          	auipc	ra,0x1
    8000391e:	c26080e7          	jalr	-986(ra) # 80004540 <releasesleep>
}
    80003922:	60e2                	ld	ra,24(sp)
    80003924:	6442                	ld	s0,16(sp)
    80003926:	64a2                	ld	s1,8(sp)
    80003928:	6902                	ld	s2,0(sp)
    8000392a:	6105                	addi	sp,sp,32
    8000392c:	8082                	ret
    panic("iunlock");
    8000392e:	00005517          	auipc	a0,0x5
    80003932:	c7250513          	addi	a0,a0,-910 # 800085a0 <syscalls+0x198>
    80003936:	ffffd097          	auipc	ra,0xffffd
    8000393a:	c0e080e7          	jalr	-1010(ra) # 80000544 <panic>

000000008000393e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000393e:	7179                	addi	sp,sp,-48
    80003940:	f406                	sd	ra,40(sp)
    80003942:	f022                	sd	s0,32(sp)
    80003944:	ec26                	sd	s1,24(sp)
    80003946:	e84a                	sd	s2,16(sp)
    80003948:	e44e                	sd	s3,8(sp)
    8000394a:	e052                	sd	s4,0(sp)
    8000394c:	1800                	addi	s0,sp,48
    8000394e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003950:	05050493          	addi	s1,a0,80
    80003954:	08050913          	addi	s2,a0,128
    80003958:	a021                	j	80003960 <itrunc+0x22>
    8000395a:	0491                	addi	s1,s1,4
    8000395c:	01248d63          	beq	s1,s2,80003976 <itrunc+0x38>
    if(ip->addrs[i]){
    80003960:	408c                	lw	a1,0(s1)
    80003962:	dde5                	beqz	a1,8000395a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003964:	0009a503          	lw	a0,0(s3)
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	8f4080e7          	jalr	-1804(ra) # 8000325c <bfree>
      ip->addrs[i] = 0;
    80003970:	0004a023          	sw	zero,0(s1)
    80003974:	b7dd                	j	8000395a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003976:	0809a583          	lw	a1,128(s3)
    8000397a:	e185                	bnez	a1,8000399a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000397c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003980:	854e                	mv	a0,s3
    80003982:	00000097          	auipc	ra,0x0
    80003986:	de4080e7          	jalr	-540(ra) # 80003766 <iupdate>
}
    8000398a:	70a2                	ld	ra,40(sp)
    8000398c:	7402                	ld	s0,32(sp)
    8000398e:	64e2                	ld	s1,24(sp)
    80003990:	6942                	ld	s2,16(sp)
    80003992:	69a2                	ld	s3,8(sp)
    80003994:	6a02                	ld	s4,0(sp)
    80003996:	6145                	addi	sp,sp,48
    80003998:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000399a:	0009a503          	lw	a0,0(s3)
    8000399e:	fffff097          	auipc	ra,0xfffff
    800039a2:	678080e7          	jalr	1656(ra) # 80003016 <bread>
    800039a6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039a8:	05850493          	addi	s1,a0,88
    800039ac:	45850913          	addi	s2,a0,1112
    800039b0:	a811                	j	800039c4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039b2:	0009a503          	lw	a0,0(s3)
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	8a6080e7          	jalr	-1882(ra) # 8000325c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039be:	0491                	addi	s1,s1,4
    800039c0:	01248563          	beq	s1,s2,800039ca <itrunc+0x8c>
      if(a[j])
    800039c4:	408c                	lw	a1,0(s1)
    800039c6:	dde5                	beqz	a1,800039be <itrunc+0x80>
    800039c8:	b7ed                	j	800039b2 <itrunc+0x74>
    brelse(bp);
    800039ca:	8552                	mv	a0,s4
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	77a080e7          	jalr	1914(ra) # 80003146 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039d4:	0809a583          	lw	a1,128(s3)
    800039d8:	0009a503          	lw	a0,0(s3)
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	880080e7          	jalr	-1920(ra) # 8000325c <bfree>
    ip->addrs[NDIRECT] = 0;
    800039e4:	0809a023          	sw	zero,128(s3)
    800039e8:	bf51                	j	8000397c <itrunc+0x3e>

00000000800039ea <iput>:
{
    800039ea:	1101                	addi	sp,sp,-32
    800039ec:	ec06                	sd	ra,24(sp)
    800039ee:	e822                	sd	s0,16(sp)
    800039f0:	e426                	sd	s1,8(sp)
    800039f2:	e04a                	sd	s2,0(sp)
    800039f4:	1000                	addi	s0,sp,32
    800039f6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039f8:	0001b517          	auipc	a0,0x1b
    800039fc:	64050513          	addi	a0,a0,1600 # 8001f038 <itable>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	1ea080e7          	jalr	490(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a08:	4498                	lw	a4,8(s1)
    80003a0a:	4785                	li	a5,1
    80003a0c:	02f70363          	beq	a4,a5,80003a32 <iput+0x48>
  ip->ref--;
    80003a10:	449c                	lw	a5,8(s1)
    80003a12:	37fd                	addiw	a5,a5,-1
    80003a14:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a16:	0001b517          	auipc	a0,0x1b
    80003a1a:	62250513          	addi	a0,a0,1570 # 8001f038 <itable>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	280080e7          	jalr	640(ra) # 80000c9e <release>
}
    80003a26:	60e2                	ld	ra,24(sp)
    80003a28:	6442                	ld	s0,16(sp)
    80003a2a:	64a2                	ld	s1,8(sp)
    80003a2c:	6902                	ld	s2,0(sp)
    80003a2e:	6105                	addi	sp,sp,32
    80003a30:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a32:	40bc                	lw	a5,64(s1)
    80003a34:	dff1                	beqz	a5,80003a10 <iput+0x26>
    80003a36:	04a49783          	lh	a5,74(s1)
    80003a3a:	fbf9                	bnez	a5,80003a10 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a3c:	01048913          	addi	s2,s1,16
    80003a40:	854a                	mv	a0,s2
    80003a42:	00001097          	auipc	ra,0x1
    80003a46:	aa8080e7          	jalr	-1368(ra) # 800044ea <acquiresleep>
    release(&itable.lock);
    80003a4a:	0001b517          	auipc	a0,0x1b
    80003a4e:	5ee50513          	addi	a0,a0,1518 # 8001f038 <itable>
    80003a52:	ffffd097          	auipc	ra,0xffffd
    80003a56:	24c080e7          	jalr	588(ra) # 80000c9e <release>
    itrunc(ip);
    80003a5a:	8526                	mv	a0,s1
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	ee2080e7          	jalr	-286(ra) # 8000393e <itrunc>
    ip->type = 0;
    80003a64:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a68:	8526                	mv	a0,s1
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	cfc080e7          	jalr	-772(ra) # 80003766 <iupdate>
    ip->valid = 0;
    80003a72:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a76:	854a                	mv	a0,s2
    80003a78:	00001097          	auipc	ra,0x1
    80003a7c:	ac8080e7          	jalr	-1336(ra) # 80004540 <releasesleep>
    acquire(&itable.lock);
    80003a80:	0001b517          	auipc	a0,0x1b
    80003a84:	5b850513          	addi	a0,a0,1464 # 8001f038 <itable>
    80003a88:	ffffd097          	auipc	ra,0xffffd
    80003a8c:	162080e7          	jalr	354(ra) # 80000bea <acquire>
    80003a90:	b741                	j	80003a10 <iput+0x26>

0000000080003a92 <iunlockput>:
{
    80003a92:	1101                	addi	sp,sp,-32
    80003a94:	ec06                	sd	ra,24(sp)
    80003a96:	e822                	sd	s0,16(sp)
    80003a98:	e426                	sd	s1,8(sp)
    80003a9a:	1000                	addi	s0,sp,32
    80003a9c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	e54080e7          	jalr	-428(ra) # 800038f2 <iunlock>
  iput(ip);
    80003aa6:	8526                	mv	a0,s1
    80003aa8:	00000097          	auipc	ra,0x0
    80003aac:	f42080e7          	jalr	-190(ra) # 800039ea <iput>
}
    80003ab0:	60e2                	ld	ra,24(sp)
    80003ab2:	6442                	ld	s0,16(sp)
    80003ab4:	64a2                	ld	s1,8(sp)
    80003ab6:	6105                	addi	sp,sp,32
    80003ab8:	8082                	ret

0000000080003aba <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aba:	1141                	addi	sp,sp,-16
    80003abc:	e422                	sd	s0,8(sp)
    80003abe:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ac0:	411c                	lw	a5,0(a0)
    80003ac2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ac4:	415c                	lw	a5,4(a0)
    80003ac6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ac8:	04451783          	lh	a5,68(a0)
    80003acc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ad0:	04a51783          	lh	a5,74(a0)
    80003ad4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ad8:	04c56783          	lwu	a5,76(a0)
    80003adc:	e99c                	sd	a5,16(a1)
}
    80003ade:	6422                	ld	s0,8(sp)
    80003ae0:	0141                	addi	sp,sp,16
    80003ae2:	8082                	ret

0000000080003ae4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae4:	457c                	lw	a5,76(a0)
    80003ae6:	0ed7e963          	bltu	a5,a3,80003bd8 <readi+0xf4>
{
    80003aea:	7159                	addi	sp,sp,-112
    80003aec:	f486                	sd	ra,104(sp)
    80003aee:	f0a2                	sd	s0,96(sp)
    80003af0:	eca6                	sd	s1,88(sp)
    80003af2:	e8ca                	sd	s2,80(sp)
    80003af4:	e4ce                	sd	s3,72(sp)
    80003af6:	e0d2                	sd	s4,64(sp)
    80003af8:	fc56                	sd	s5,56(sp)
    80003afa:	f85a                	sd	s6,48(sp)
    80003afc:	f45e                	sd	s7,40(sp)
    80003afe:	f062                	sd	s8,32(sp)
    80003b00:	ec66                	sd	s9,24(sp)
    80003b02:	e86a                	sd	s10,16(sp)
    80003b04:	e46e                	sd	s11,8(sp)
    80003b06:	1880                	addi	s0,sp,112
    80003b08:	8b2a                	mv	s6,a0
    80003b0a:	8bae                	mv	s7,a1
    80003b0c:	8a32                	mv	s4,a2
    80003b0e:	84b6                	mv	s1,a3
    80003b10:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b12:	9f35                	addw	a4,a4,a3
    return 0;
    80003b14:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b16:	0ad76063          	bltu	a4,a3,80003bb6 <readi+0xd2>
  if(off + n > ip->size)
    80003b1a:	00e7f463          	bgeu	a5,a4,80003b22 <readi+0x3e>
    n = ip->size - off;
    80003b1e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b22:	0a0a8963          	beqz	s5,80003bd4 <readi+0xf0>
    80003b26:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b28:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b2c:	5c7d                	li	s8,-1
    80003b2e:	a82d                	j	80003b68 <readi+0x84>
    80003b30:	020d1d93          	slli	s11,s10,0x20
    80003b34:	020ddd93          	srli	s11,s11,0x20
    80003b38:	05890613          	addi	a2,s2,88
    80003b3c:	86ee                	mv	a3,s11
    80003b3e:	963a                	add	a2,a2,a4
    80003b40:	85d2                	mv	a1,s4
    80003b42:	855e                	mv	a0,s7
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	ae8080e7          	jalr	-1304(ra) # 8000262c <either_copyout>
    80003b4c:	05850d63          	beq	a0,s8,80003ba6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b50:	854a                	mv	a0,s2
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	5f4080e7          	jalr	1524(ra) # 80003146 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b5a:	013d09bb          	addw	s3,s10,s3
    80003b5e:	009d04bb          	addw	s1,s10,s1
    80003b62:	9a6e                	add	s4,s4,s11
    80003b64:	0559f763          	bgeu	s3,s5,80003bb2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003b68:	00a4d59b          	srliw	a1,s1,0xa
    80003b6c:	855a                	mv	a0,s6
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	8a2080e7          	jalr	-1886(ra) # 80003410 <bmap>
    80003b76:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b7a:	cd85                	beqz	a1,80003bb2 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b7c:	000b2503          	lw	a0,0(s6)
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	496080e7          	jalr	1174(ra) # 80003016 <bread>
    80003b88:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8a:	3ff4f713          	andi	a4,s1,1023
    80003b8e:	40ec87bb          	subw	a5,s9,a4
    80003b92:	413a86bb          	subw	a3,s5,s3
    80003b96:	8d3e                	mv	s10,a5
    80003b98:	2781                	sext.w	a5,a5
    80003b9a:	0006861b          	sext.w	a2,a3
    80003b9e:	f8f679e3          	bgeu	a2,a5,80003b30 <readi+0x4c>
    80003ba2:	8d36                	mv	s10,a3
    80003ba4:	b771                	j	80003b30 <readi+0x4c>
      brelse(bp);
    80003ba6:	854a                	mv	a0,s2
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	59e080e7          	jalr	1438(ra) # 80003146 <brelse>
      tot = -1;
    80003bb0:	59fd                	li	s3,-1
  }
  return tot;
    80003bb2:	0009851b          	sext.w	a0,s3
}
    80003bb6:	70a6                	ld	ra,104(sp)
    80003bb8:	7406                	ld	s0,96(sp)
    80003bba:	64e6                	ld	s1,88(sp)
    80003bbc:	6946                	ld	s2,80(sp)
    80003bbe:	69a6                	ld	s3,72(sp)
    80003bc0:	6a06                	ld	s4,64(sp)
    80003bc2:	7ae2                	ld	s5,56(sp)
    80003bc4:	7b42                	ld	s6,48(sp)
    80003bc6:	7ba2                	ld	s7,40(sp)
    80003bc8:	7c02                	ld	s8,32(sp)
    80003bca:	6ce2                	ld	s9,24(sp)
    80003bcc:	6d42                	ld	s10,16(sp)
    80003bce:	6da2                	ld	s11,8(sp)
    80003bd0:	6165                	addi	sp,sp,112
    80003bd2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd4:	89d6                	mv	s3,s5
    80003bd6:	bff1                	j	80003bb2 <readi+0xce>
    return 0;
    80003bd8:	4501                	li	a0,0
}
    80003bda:	8082                	ret

0000000080003bdc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bdc:	457c                	lw	a5,76(a0)
    80003bde:	10d7e863          	bltu	a5,a3,80003cee <writei+0x112>
{
    80003be2:	7159                	addi	sp,sp,-112
    80003be4:	f486                	sd	ra,104(sp)
    80003be6:	f0a2                	sd	s0,96(sp)
    80003be8:	eca6                	sd	s1,88(sp)
    80003bea:	e8ca                	sd	s2,80(sp)
    80003bec:	e4ce                	sd	s3,72(sp)
    80003bee:	e0d2                	sd	s4,64(sp)
    80003bf0:	fc56                	sd	s5,56(sp)
    80003bf2:	f85a                	sd	s6,48(sp)
    80003bf4:	f45e                	sd	s7,40(sp)
    80003bf6:	f062                	sd	s8,32(sp)
    80003bf8:	ec66                	sd	s9,24(sp)
    80003bfa:	e86a                	sd	s10,16(sp)
    80003bfc:	e46e                	sd	s11,8(sp)
    80003bfe:	1880                	addi	s0,sp,112
    80003c00:	8aaa                	mv	s5,a0
    80003c02:	8bae                	mv	s7,a1
    80003c04:	8a32                	mv	s4,a2
    80003c06:	8936                	mv	s2,a3
    80003c08:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c0a:	00e687bb          	addw	a5,a3,a4
    80003c0e:	0ed7e263          	bltu	a5,a3,80003cf2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c12:	00043737          	lui	a4,0x43
    80003c16:	0ef76063          	bltu	a4,a5,80003cf6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c1a:	0c0b0863          	beqz	s6,80003cea <writei+0x10e>
    80003c1e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c20:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c24:	5c7d                	li	s8,-1
    80003c26:	a091                	j	80003c6a <writei+0x8e>
    80003c28:	020d1d93          	slli	s11,s10,0x20
    80003c2c:	020ddd93          	srli	s11,s11,0x20
    80003c30:	05848513          	addi	a0,s1,88
    80003c34:	86ee                	mv	a3,s11
    80003c36:	8652                	mv	a2,s4
    80003c38:	85de                	mv	a1,s7
    80003c3a:	953a                	add	a0,a0,a4
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	a46080e7          	jalr	-1466(ra) # 80002682 <either_copyin>
    80003c44:	07850263          	beq	a0,s8,80003ca8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c48:	8526                	mv	a0,s1
    80003c4a:	00000097          	auipc	ra,0x0
    80003c4e:	780080e7          	jalr	1920(ra) # 800043ca <log_write>
    brelse(bp);
    80003c52:	8526                	mv	a0,s1
    80003c54:	fffff097          	auipc	ra,0xfffff
    80003c58:	4f2080e7          	jalr	1266(ra) # 80003146 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c5c:	013d09bb          	addw	s3,s10,s3
    80003c60:	012d093b          	addw	s2,s10,s2
    80003c64:	9a6e                	add	s4,s4,s11
    80003c66:	0569f663          	bgeu	s3,s6,80003cb2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c6a:	00a9559b          	srliw	a1,s2,0xa
    80003c6e:	8556                	mv	a0,s5
    80003c70:	fffff097          	auipc	ra,0xfffff
    80003c74:	7a0080e7          	jalr	1952(ra) # 80003410 <bmap>
    80003c78:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c7c:	c99d                	beqz	a1,80003cb2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c7e:	000aa503          	lw	a0,0(s5)
    80003c82:	fffff097          	auipc	ra,0xfffff
    80003c86:	394080e7          	jalr	916(ra) # 80003016 <bread>
    80003c8a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c8c:	3ff97713          	andi	a4,s2,1023
    80003c90:	40ec87bb          	subw	a5,s9,a4
    80003c94:	413b06bb          	subw	a3,s6,s3
    80003c98:	8d3e                	mv	s10,a5
    80003c9a:	2781                	sext.w	a5,a5
    80003c9c:	0006861b          	sext.w	a2,a3
    80003ca0:	f8f674e3          	bgeu	a2,a5,80003c28 <writei+0x4c>
    80003ca4:	8d36                	mv	s10,a3
    80003ca6:	b749                	j	80003c28 <writei+0x4c>
      brelse(bp);
    80003ca8:	8526                	mv	a0,s1
    80003caa:	fffff097          	auipc	ra,0xfffff
    80003cae:	49c080e7          	jalr	1180(ra) # 80003146 <brelse>
  }

  if(off > ip->size)
    80003cb2:	04caa783          	lw	a5,76(s5)
    80003cb6:	0127f463          	bgeu	a5,s2,80003cbe <writei+0xe2>
    ip->size = off;
    80003cba:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cbe:	8556                	mv	a0,s5
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	aa6080e7          	jalr	-1370(ra) # 80003766 <iupdate>

  return tot;
    80003cc8:	0009851b          	sext.w	a0,s3
}
    80003ccc:	70a6                	ld	ra,104(sp)
    80003cce:	7406                	ld	s0,96(sp)
    80003cd0:	64e6                	ld	s1,88(sp)
    80003cd2:	6946                	ld	s2,80(sp)
    80003cd4:	69a6                	ld	s3,72(sp)
    80003cd6:	6a06                	ld	s4,64(sp)
    80003cd8:	7ae2                	ld	s5,56(sp)
    80003cda:	7b42                	ld	s6,48(sp)
    80003cdc:	7ba2                	ld	s7,40(sp)
    80003cde:	7c02                	ld	s8,32(sp)
    80003ce0:	6ce2                	ld	s9,24(sp)
    80003ce2:	6d42                	ld	s10,16(sp)
    80003ce4:	6da2                	ld	s11,8(sp)
    80003ce6:	6165                	addi	sp,sp,112
    80003ce8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cea:	89da                	mv	s3,s6
    80003cec:	bfc9                	j	80003cbe <writei+0xe2>
    return -1;
    80003cee:	557d                	li	a0,-1
}
    80003cf0:	8082                	ret
    return -1;
    80003cf2:	557d                	li	a0,-1
    80003cf4:	bfe1                	j	80003ccc <writei+0xf0>
    return -1;
    80003cf6:	557d                	li	a0,-1
    80003cf8:	bfd1                	j	80003ccc <writei+0xf0>

0000000080003cfa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cfa:	1141                	addi	sp,sp,-16
    80003cfc:	e406                	sd	ra,8(sp)
    80003cfe:	e022                	sd	s0,0(sp)
    80003d00:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d02:	4639                	li	a2,14
    80003d04:	ffffd097          	auipc	ra,0xffffd
    80003d08:	0ba080e7          	jalr	186(ra) # 80000dbe <strncmp>
}
    80003d0c:	60a2                	ld	ra,8(sp)
    80003d0e:	6402                	ld	s0,0(sp)
    80003d10:	0141                	addi	sp,sp,16
    80003d12:	8082                	ret

0000000080003d14 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d14:	7139                	addi	sp,sp,-64
    80003d16:	fc06                	sd	ra,56(sp)
    80003d18:	f822                	sd	s0,48(sp)
    80003d1a:	f426                	sd	s1,40(sp)
    80003d1c:	f04a                	sd	s2,32(sp)
    80003d1e:	ec4e                	sd	s3,24(sp)
    80003d20:	e852                	sd	s4,16(sp)
    80003d22:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d24:	04451703          	lh	a4,68(a0)
    80003d28:	4785                	li	a5,1
    80003d2a:	00f71a63          	bne	a4,a5,80003d3e <dirlookup+0x2a>
    80003d2e:	892a                	mv	s2,a0
    80003d30:	89ae                	mv	s3,a1
    80003d32:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d34:	457c                	lw	a5,76(a0)
    80003d36:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d38:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d3a:	e79d                	bnez	a5,80003d68 <dirlookup+0x54>
    80003d3c:	a8a5                	j	80003db4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d3e:	00005517          	auipc	a0,0x5
    80003d42:	86a50513          	addi	a0,a0,-1942 # 800085a8 <syscalls+0x1a0>
    80003d46:	ffffc097          	auipc	ra,0xffffc
    80003d4a:	7fe080e7          	jalr	2046(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003d4e:	00005517          	auipc	a0,0x5
    80003d52:	87250513          	addi	a0,a0,-1934 # 800085c0 <syscalls+0x1b8>
    80003d56:	ffffc097          	auipc	ra,0xffffc
    80003d5a:	7ee080e7          	jalr	2030(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d5e:	24c1                	addiw	s1,s1,16
    80003d60:	04c92783          	lw	a5,76(s2)
    80003d64:	04f4f763          	bgeu	s1,a5,80003db2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d68:	4741                	li	a4,16
    80003d6a:	86a6                	mv	a3,s1
    80003d6c:	fc040613          	addi	a2,s0,-64
    80003d70:	4581                	li	a1,0
    80003d72:	854a                	mv	a0,s2
    80003d74:	00000097          	auipc	ra,0x0
    80003d78:	d70080e7          	jalr	-656(ra) # 80003ae4 <readi>
    80003d7c:	47c1                	li	a5,16
    80003d7e:	fcf518e3          	bne	a0,a5,80003d4e <dirlookup+0x3a>
    if(de.inum == 0)
    80003d82:	fc045783          	lhu	a5,-64(s0)
    80003d86:	dfe1                	beqz	a5,80003d5e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d88:	fc240593          	addi	a1,s0,-62
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	f6c080e7          	jalr	-148(ra) # 80003cfa <namecmp>
    80003d96:	f561                	bnez	a0,80003d5e <dirlookup+0x4a>
      if(poff)
    80003d98:	000a0463          	beqz	s4,80003da0 <dirlookup+0x8c>
        *poff = off;
    80003d9c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003da0:	fc045583          	lhu	a1,-64(s0)
    80003da4:	00092503          	lw	a0,0(s2)
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	750080e7          	jalr	1872(ra) # 800034f8 <iget>
    80003db0:	a011                	j	80003db4 <dirlookup+0xa0>
  return 0;
    80003db2:	4501                	li	a0,0
}
    80003db4:	70e2                	ld	ra,56(sp)
    80003db6:	7442                	ld	s0,48(sp)
    80003db8:	74a2                	ld	s1,40(sp)
    80003dba:	7902                	ld	s2,32(sp)
    80003dbc:	69e2                	ld	s3,24(sp)
    80003dbe:	6a42                	ld	s4,16(sp)
    80003dc0:	6121                	addi	sp,sp,64
    80003dc2:	8082                	ret

0000000080003dc4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dc4:	711d                	addi	sp,sp,-96
    80003dc6:	ec86                	sd	ra,88(sp)
    80003dc8:	e8a2                	sd	s0,80(sp)
    80003dca:	e4a6                	sd	s1,72(sp)
    80003dcc:	e0ca                	sd	s2,64(sp)
    80003dce:	fc4e                	sd	s3,56(sp)
    80003dd0:	f852                	sd	s4,48(sp)
    80003dd2:	f456                	sd	s5,40(sp)
    80003dd4:	f05a                	sd	s6,32(sp)
    80003dd6:	ec5e                	sd	s7,24(sp)
    80003dd8:	e862                	sd	s8,16(sp)
    80003dda:	e466                	sd	s9,8(sp)
    80003ddc:	1080                	addi	s0,sp,96
    80003dde:	84aa                	mv	s1,a0
    80003de0:	8b2e                	mv	s6,a1
    80003de2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003de4:	00054703          	lbu	a4,0(a0)
    80003de8:	02f00793          	li	a5,47
    80003dec:	02f70363          	beq	a4,a5,80003e12 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003df0:	ffffe097          	auipc	ra,0xffffe
    80003df4:	d24080e7          	jalr	-732(ra) # 80001b14 <myproc>
    80003df8:	15053503          	ld	a0,336(a0)
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	9f6080e7          	jalr	-1546(ra) # 800037f2 <idup>
    80003e04:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e06:	02f00913          	li	s2,47
  len = path - s;
    80003e0a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e0c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e0e:	4c05                	li	s8,1
    80003e10:	a865                	j	80003ec8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e12:	4585                	li	a1,1
    80003e14:	4505                	li	a0,1
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	6e2080e7          	jalr	1762(ra) # 800034f8 <iget>
    80003e1e:	89aa                	mv	s3,a0
    80003e20:	b7dd                	j	80003e06 <namex+0x42>
      iunlockput(ip);
    80003e22:	854e                	mv	a0,s3
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	c6e080e7          	jalr	-914(ra) # 80003a92 <iunlockput>
      return 0;
    80003e2c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e2e:	854e                	mv	a0,s3
    80003e30:	60e6                	ld	ra,88(sp)
    80003e32:	6446                	ld	s0,80(sp)
    80003e34:	64a6                	ld	s1,72(sp)
    80003e36:	6906                	ld	s2,64(sp)
    80003e38:	79e2                	ld	s3,56(sp)
    80003e3a:	7a42                	ld	s4,48(sp)
    80003e3c:	7aa2                	ld	s5,40(sp)
    80003e3e:	7b02                	ld	s6,32(sp)
    80003e40:	6be2                	ld	s7,24(sp)
    80003e42:	6c42                	ld	s8,16(sp)
    80003e44:	6ca2                	ld	s9,8(sp)
    80003e46:	6125                	addi	sp,sp,96
    80003e48:	8082                	ret
      iunlock(ip);
    80003e4a:	854e                	mv	a0,s3
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	aa6080e7          	jalr	-1370(ra) # 800038f2 <iunlock>
      return ip;
    80003e54:	bfe9                	j	80003e2e <namex+0x6a>
      iunlockput(ip);
    80003e56:	854e                	mv	a0,s3
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	c3a080e7          	jalr	-966(ra) # 80003a92 <iunlockput>
      return 0;
    80003e60:	89d2                	mv	s3,s4
    80003e62:	b7f1                	j	80003e2e <namex+0x6a>
  len = path - s;
    80003e64:	40b48633          	sub	a2,s1,a1
    80003e68:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e6c:	094cd463          	bge	s9,s4,80003ef4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e70:	4639                	li	a2,14
    80003e72:	8556                	mv	a0,s5
    80003e74:	ffffd097          	auipc	ra,0xffffd
    80003e78:	ed2080e7          	jalr	-302(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003e7c:	0004c783          	lbu	a5,0(s1)
    80003e80:	01279763          	bne	a5,s2,80003e8e <namex+0xca>
    path++;
    80003e84:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	ff278de3          	beq	a5,s2,80003e84 <namex+0xc0>
    ilock(ip);
    80003e8e:	854e                	mv	a0,s3
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	9a0080e7          	jalr	-1632(ra) # 80003830 <ilock>
    if(ip->type != T_DIR){
    80003e98:	04499783          	lh	a5,68(s3)
    80003e9c:	f98793e3          	bne	a5,s8,80003e22 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ea0:	000b0563          	beqz	s6,80003eaa <namex+0xe6>
    80003ea4:	0004c783          	lbu	a5,0(s1)
    80003ea8:	d3cd                	beqz	a5,80003e4a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003eaa:	865e                	mv	a2,s7
    80003eac:	85d6                	mv	a1,s5
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	e64080e7          	jalr	-412(ra) # 80003d14 <dirlookup>
    80003eb8:	8a2a                	mv	s4,a0
    80003eba:	dd51                	beqz	a0,80003e56 <namex+0x92>
    iunlockput(ip);
    80003ebc:	854e                	mv	a0,s3
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	bd4080e7          	jalr	-1068(ra) # 80003a92 <iunlockput>
    ip = next;
    80003ec6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ec8:	0004c783          	lbu	a5,0(s1)
    80003ecc:	05279763          	bne	a5,s2,80003f1a <namex+0x156>
    path++;
    80003ed0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ed2:	0004c783          	lbu	a5,0(s1)
    80003ed6:	ff278de3          	beq	a5,s2,80003ed0 <namex+0x10c>
  if(*path == 0)
    80003eda:	c79d                	beqz	a5,80003f08 <namex+0x144>
    path++;
    80003edc:	85a6                	mv	a1,s1
  len = path - s;
    80003ede:	8a5e                	mv	s4,s7
    80003ee0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ee2:	01278963          	beq	a5,s2,80003ef4 <namex+0x130>
    80003ee6:	dfbd                	beqz	a5,80003e64 <namex+0xa0>
    path++;
    80003ee8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	ff279ce3          	bne	a5,s2,80003ee6 <namex+0x122>
    80003ef2:	bf8d                	j	80003e64 <namex+0xa0>
    memmove(name, s, len);
    80003ef4:	2601                	sext.w	a2,a2
    80003ef6:	8556                	mv	a0,s5
    80003ef8:	ffffd097          	auipc	ra,0xffffd
    80003efc:	e4e080e7          	jalr	-434(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003f00:	9a56                	add	s4,s4,s5
    80003f02:	000a0023          	sb	zero,0(s4)
    80003f06:	bf9d                	j	80003e7c <namex+0xb8>
  if(nameiparent){
    80003f08:	f20b03e3          	beqz	s6,80003e2e <namex+0x6a>
    iput(ip);
    80003f0c:	854e                	mv	a0,s3
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	adc080e7          	jalr	-1316(ra) # 800039ea <iput>
    return 0;
    80003f16:	4981                	li	s3,0
    80003f18:	bf19                	j	80003e2e <namex+0x6a>
  if(*path == 0)
    80003f1a:	d7fd                	beqz	a5,80003f08 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f1c:	0004c783          	lbu	a5,0(s1)
    80003f20:	85a6                	mv	a1,s1
    80003f22:	b7d1                	j	80003ee6 <namex+0x122>

0000000080003f24 <dirlink>:
{
    80003f24:	7139                	addi	sp,sp,-64
    80003f26:	fc06                	sd	ra,56(sp)
    80003f28:	f822                	sd	s0,48(sp)
    80003f2a:	f426                	sd	s1,40(sp)
    80003f2c:	f04a                	sd	s2,32(sp)
    80003f2e:	ec4e                	sd	s3,24(sp)
    80003f30:	e852                	sd	s4,16(sp)
    80003f32:	0080                	addi	s0,sp,64
    80003f34:	892a                	mv	s2,a0
    80003f36:	8a2e                	mv	s4,a1
    80003f38:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f3a:	4601                	li	a2,0
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	dd8080e7          	jalr	-552(ra) # 80003d14 <dirlookup>
    80003f44:	e93d                	bnez	a0,80003fba <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f46:	04c92483          	lw	s1,76(s2)
    80003f4a:	c49d                	beqz	s1,80003f78 <dirlink+0x54>
    80003f4c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f4e:	4741                	li	a4,16
    80003f50:	86a6                	mv	a3,s1
    80003f52:	fc040613          	addi	a2,s0,-64
    80003f56:	4581                	li	a1,0
    80003f58:	854a                	mv	a0,s2
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	b8a080e7          	jalr	-1142(ra) # 80003ae4 <readi>
    80003f62:	47c1                	li	a5,16
    80003f64:	06f51163          	bne	a0,a5,80003fc6 <dirlink+0xa2>
    if(de.inum == 0)
    80003f68:	fc045783          	lhu	a5,-64(s0)
    80003f6c:	c791                	beqz	a5,80003f78 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f6e:	24c1                	addiw	s1,s1,16
    80003f70:	04c92783          	lw	a5,76(s2)
    80003f74:	fcf4ede3          	bltu	s1,a5,80003f4e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f78:	4639                	li	a2,14
    80003f7a:	85d2                	mv	a1,s4
    80003f7c:	fc240513          	addi	a0,s0,-62
    80003f80:	ffffd097          	auipc	ra,0xffffd
    80003f84:	e7a080e7          	jalr	-390(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003f88:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f8c:	4741                	li	a4,16
    80003f8e:	86a6                	mv	a3,s1
    80003f90:	fc040613          	addi	a2,s0,-64
    80003f94:	4581                	li	a1,0
    80003f96:	854a                	mv	a0,s2
    80003f98:	00000097          	auipc	ra,0x0
    80003f9c:	c44080e7          	jalr	-956(ra) # 80003bdc <writei>
    80003fa0:	1541                	addi	a0,a0,-16
    80003fa2:	00a03533          	snez	a0,a0
    80003fa6:	40a00533          	neg	a0,a0
}
    80003faa:	70e2                	ld	ra,56(sp)
    80003fac:	7442                	ld	s0,48(sp)
    80003fae:	74a2                	ld	s1,40(sp)
    80003fb0:	7902                	ld	s2,32(sp)
    80003fb2:	69e2                	ld	s3,24(sp)
    80003fb4:	6a42                	ld	s4,16(sp)
    80003fb6:	6121                	addi	sp,sp,64
    80003fb8:	8082                	ret
    iput(ip);
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	a30080e7          	jalr	-1488(ra) # 800039ea <iput>
    return -1;
    80003fc2:	557d                	li	a0,-1
    80003fc4:	b7dd                	j	80003faa <dirlink+0x86>
      panic("dirlink read");
    80003fc6:	00004517          	auipc	a0,0x4
    80003fca:	60a50513          	addi	a0,a0,1546 # 800085d0 <syscalls+0x1c8>
    80003fce:	ffffc097          	auipc	ra,0xffffc
    80003fd2:	576080e7          	jalr	1398(ra) # 80000544 <panic>

0000000080003fd6 <namei>:

struct inode*
namei(char *path)
{
    80003fd6:	1101                	addi	sp,sp,-32
    80003fd8:	ec06                	sd	ra,24(sp)
    80003fda:	e822                	sd	s0,16(sp)
    80003fdc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fde:	fe040613          	addi	a2,s0,-32
    80003fe2:	4581                	li	a1,0
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	de0080e7          	jalr	-544(ra) # 80003dc4 <namex>
}
    80003fec:	60e2                	ld	ra,24(sp)
    80003fee:	6442                	ld	s0,16(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret

0000000080003ff4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ff4:	1141                	addi	sp,sp,-16
    80003ff6:	e406                	sd	ra,8(sp)
    80003ff8:	e022                	sd	s0,0(sp)
    80003ffa:	0800                	addi	s0,sp,16
    80003ffc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ffe:	4585                	li	a1,1
    80004000:	00000097          	auipc	ra,0x0
    80004004:	dc4080e7          	jalr	-572(ra) # 80003dc4 <namex>
}
    80004008:	60a2                	ld	ra,8(sp)
    8000400a:	6402                	ld	s0,0(sp)
    8000400c:	0141                	addi	sp,sp,16
    8000400e:	8082                	ret

0000000080004010 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004010:	1101                	addi	sp,sp,-32
    80004012:	ec06                	sd	ra,24(sp)
    80004014:	e822                	sd	s0,16(sp)
    80004016:	e426                	sd	s1,8(sp)
    80004018:	e04a                	sd	s2,0(sp)
    8000401a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000401c:	0001d917          	auipc	s2,0x1d
    80004020:	ac490913          	addi	s2,s2,-1340 # 80020ae0 <log>
    80004024:	01892583          	lw	a1,24(s2)
    80004028:	02892503          	lw	a0,40(s2)
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	fea080e7          	jalr	-22(ra) # 80003016 <bread>
    80004034:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004036:	02c92683          	lw	a3,44(s2)
    8000403a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000403c:	02d05763          	blez	a3,8000406a <write_head+0x5a>
    80004040:	0001d797          	auipc	a5,0x1d
    80004044:	ad078793          	addi	a5,a5,-1328 # 80020b10 <log+0x30>
    80004048:	05c50713          	addi	a4,a0,92
    8000404c:	36fd                	addiw	a3,a3,-1
    8000404e:	1682                	slli	a3,a3,0x20
    80004050:	9281                	srli	a3,a3,0x20
    80004052:	068a                	slli	a3,a3,0x2
    80004054:	0001d617          	auipc	a2,0x1d
    80004058:	ac060613          	addi	a2,a2,-1344 # 80020b14 <log+0x34>
    8000405c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000405e:	4390                	lw	a2,0(a5)
    80004060:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004062:	0791                	addi	a5,a5,4
    80004064:	0711                	addi	a4,a4,4
    80004066:	fed79ce3          	bne	a5,a3,8000405e <write_head+0x4e>
  }
  bwrite(buf);
    8000406a:	8526                	mv	a0,s1
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	09c080e7          	jalr	156(ra) # 80003108 <bwrite>
  brelse(buf);
    80004074:	8526                	mv	a0,s1
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	0d0080e7          	jalr	208(ra) # 80003146 <brelse>
}
    8000407e:	60e2                	ld	ra,24(sp)
    80004080:	6442                	ld	s0,16(sp)
    80004082:	64a2                	ld	s1,8(sp)
    80004084:	6902                	ld	s2,0(sp)
    80004086:	6105                	addi	sp,sp,32
    80004088:	8082                	ret

000000008000408a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408a:	0001d797          	auipc	a5,0x1d
    8000408e:	a827a783          	lw	a5,-1406(a5) # 80020b0c <log+0x2c>
    80004092:	0af05d63          	blez	a5,8000414c <install_trans+0xc2>
{
    80004096:	7139                	addi	sp,sp,-64
    80004098:	fc06                	sd	ra,56(sp)
    8000409a:	f822                	sd	s0,48(sp)
    8000409c:	f426                	sd	s1,40(sp)
    8000409e:	f04a                	sd	s2,32(sp)
    800040a0:	ec4e                	sd	s3,24(sp)
    800040a2:	e852                	sd	s4,16(sp)
    800040a4:	e456                	sd	s5,8(sp)
    800040a6:	e05a                	sd	s6,0(sp)
    800040a8:	0080                	addi	s0,sp,64
    800040aa:	8b2a                	mv	s6,a0
    800040ac:	0001da97          	auipc	s5,0x1d
    800040b0:	a64a8a93          	addi	s5,s5,-1436 # 80020b10 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040b6:	0001d997          	auipc	s3,0x1d
    800040ba:	a2a98993          	addi	s3,s3,-1494 # 80020ae0 <log>
    800040be:	a035                	j	800040ea <install_trans+0x60>
      bunpin(dbuf);
    800040c0:	8526                	mv	a0,s1
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	15e080e7          	jalr	350(ra) # 80003220 <bunpin>
    brelse(lbuf);
    800040ca:	854a                	mv	a0,s2
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	07a080e7          	jalr	122(ra) # 80003146 <brelse>
    brelse(dbuf);
    800040d4:	8526                	mv	a0,s1
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	070080e7          	jalr	112(ra) # 80003146 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040de:	2a05                	addiw	s4,s4,1
    800040e0:	0a91                	addi	s5,s5,4
    800040e2:	02c9a783          	lw	a5,44(s3)
    800040e6:	04fa5963          	bge	s4,a5,80004138 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ea:	0189a583          	lw	a1,24(s3)
    800040ee:	014585bb          	addw	a1,a1,s4
    800040f2:	2585                	addiw	a1,a1,1
    800040f4:	0289a503          	lw	a0,40(s3)
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	f1e080e7          	jalr	-226(ra) # 80003016 <bread>
    80004100:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004102:	000aa583          	lw	a1,0(s5)
    80004106:	0289a503          	lw	a0,40(s3)
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	f0c080e7          	jalr	-244(ra) # 80003016 <bread>
    80004112:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004114:	40000613          	li	a2,1024
    80004118:	05890593          	addi	a1,s2,88
    8000411c:	05850513          	addi	a0,a0,88
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	c26080e7          	jalr	-986(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004128:	8526                	mv	a0,s1
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	fde080e7          	jalr	-34(ra) # 80003108 <bwrite>
    if(recovering == 0)
    80004132:	f80b1ce3          	bnez	s6,800040ca <install_trans+0x40>
    80004136:	b769                	j	800040c0 <install_trans+0x36>
}
    80004138:	70e2                	ld	ra,56(sp)
    8000413a:	7442                	ld	s0,48(sp)
    8000413c:	74a2                	ld	s1,40(sp)
    8000413e:	7902                	ld	s2,32(sp)
    80004140:	69e2                	ld	s3,24(sp)
    80004142:	6a42                	ld	s4,16(sp)
    80004144:	6aa2                	ld	s5,8(sp)
    80004146:	6b02                	ld	s6,0(sp)
    80004148:	6121                	addi	sp,sp,64
    8000414a:	8082                	ret
    8000414c:	8082                	ret

000000008000414e <initlog>:
{
    8000414e:	7179                	addi	sp,sp,-48
    80004150:	f406                	sd	ra,40(sp)
    80004152:	f022                	sd	s0,32(sp)
    80004154:	ec26                	sd	s1,24(sp)
    80004156:	e84a                	sd	s2,16(sp)
    80004158:	e44e                	sd	s3,8(sp)
    8000415a:	1800                	addi	s0,sp,48
    8000415c:	892a                	mv	s2,a0
    8000415e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004160:	0001d497          	auipc	s1,0x1d
    80004164:	98048493          	addi	s1,s1,-1664 # 80020ae0 <log>
    80004168:	00004597          	auipc	a1,0x4
    8000416c:	47858593          	addi	a1,a1,1144 # 800085e0 <syscalls+0x1d8>
    80004170:	8526                	mv	a0,s1
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	9e8080e7          	jalr	-1560(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000417a:	0149a583          	lw	a1,20(s3)
    8000417e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004180:	0109a783          	lw	a5,16(s3)
    80004184:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004186:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000418a:	854a                	mv	a0,s2
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	e8a080e7          	jalr	-374(ra) # 80003016 <bread>
  log.lh.n = lh->n;
    80004194:	4d3c                	lw	a5,88(a0)
    80004196:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004198:	02f05563          	blez	a5,800041c2 <initlog+0x74>
    8000419c:	05c50713          	addi	a4,a0,92
    800041a0:	0001d697          	auipc	a3,0x1d
    800041a4:	97068693          	addi	a3,a3,-1680 # 80020b10 <log+0x30>
    800041a8:	37fd                	addiw	a5,a5,-1
    800041aa:	1782                	slli	a5,a5,0x20
    800041ac:	9381                	srli	a5,a5,0x20
    800041ae:	078a                	slli	a5,a5,0x2
    800041b0:	06050613          	addi	a2,a0,96
    800041b4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041b6:	4310                	lw	a2,0(a4)
    800041b8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041ba:	0711                	addi	a4,a4,4
    800041bc:	0691                	addi	a3,a3,4
    800041be:	fef71ce3          	bne	a4,a5,800041b6 <initlog+0x68>
  brelse(buf);
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	f84080e7          	jalr	-124(ra) # 80003146 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041ca:	4505                	li	a0,1
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	ebe080e7          	jalr	-322(ra) # 8000408a <install_trans>
  log.lh.n = 0;
    800041d4:	0001d797          	auipc	a5,0x1d
    800041d8:	9207ac23          	sw	zero,-1736(a5) # 80020b0c <log+0x2c>
  write_head(); // clear the log
    800041dc:	00000097          	auipc	ra,0x0
    800041e0:	e34080e7          	jalr	-460(ra) # 80004010 <write_head>
}
    800041e4:	70a2                	ld	ra,40(sp)
    800041e6:	7402                	ld	s0,32(sp)
    800041e8:	64e2                	ld	s1,24(sp)
    800041ea:	6942                	ld	s2,16(sp)
    800041ec:	69a2                	ld	s3,8(sp)
    800041ee:	6145                	addi	sp,sp,48
    800041f0:	8082                	ret

00000000800041f2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041f2:	1101                	addi	sp,sp,-32
    800041f4:	ec06                	sd	ra,24(sp)
    800041f6:	e822                	sd	s0,16(sp)
    800041f8:	e426                	sd	s1,8(sp)
    800041fa:	e04a                	sd	s2,0(sp)
    800041fc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041fe:	0001d517          	auipc	a0,0x1d
    80004202:	8e250513          	addi	a0,a0,-1822 # 80020ae0 <log>
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	9e4080e7          	jalr	-1564(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    8000420e:	0001d497          	auipc	s1,0x1d
    80004212:	8d248493          	addi	s1,s1,-1838 # 80020ae0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004216:	4979                	li	s2,30
    80004218:	a039                	j	80004226 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000421a:	85a6                	mv	a1,s1
    8000421c:	8526                	mv	a0,s1
    8000421e:	ffffe097          	auipc	ra,0xffffe
    80004222:	006080e7          	jalr	6(ra) # 80002224 <sleep>
    if(log.committing){
    80004226:	50dc                	lw	a5,36(s1)
    80004228:	fbed                	bnez	a5,8000421a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000422a:	509c                	lw	a5,32(s1)
    8000422c:	0017871b          	addiw	a4,a5,1
    80004230:	0007069b          	sext.w	a3,a4
    80004234:	0027179b          	slliw	a5,a4,0x2
    80004238:	9fb9                	addw	a5,a5,a4
    8000423a:	0017979b          	slliw	a5,a5,0x1
    8000423e:	54d8                	lw	a4,44(s1)
    80004240:	9fb9                	addw	a5,a5,a4
    80004242:	00f95963          	bge	s2,a5,80004254 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004246:	85a6                	mv	a1,s1
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffe097          	auipc	ra,0xffffe
    8000424e:	fda080e7          	jalr	-38(ra) # 80002224 <sleep>
    80004252:	bfd1                	j	80004226 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004254:	0001d517          	auipc	a0,0x1d
    80004258:	88c50513          	addi	a0,a0,-1908 # 80020ae0 <log>
    8000425c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	a40080e7          	jalr	-1472(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004266:	60e2                	ld	ra,24(sp)
    80004268:	6442                	ld	s0,16(sp)
    8000426a:	64a2                	ld	s1,8(sp)
    8000426c:	6902                	ld	s2,0(sp)
    8000426e:	6105                	addi	sp,sp,32
    80004270:	8082                	ret

0000000080004272 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004272:	7139                	addi	sp,sp,-64
    80004274:	fc06                	sd	ra,56(sp)
    80004276:	f822                	sd	s0,48(sp)
    80004278:	f426                	sd	s1,40(sp)
    8000427a:	f04a                	sd	s2,32(sp)
    8000427c:	ec4e                	sd	s3,24(sp)
    8000427e:	e852                	sd	s4,16(sp)
    80004280:	e456                	sd	s5,8(sp)
    80004282:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004284:	0001d497          	auipc	s1,0x1d
    80004288:	85c48493          	addi	s1,s1,-1956 # 80020ae0 <log>
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	95c080e7          	jalr	-1700(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004296:	509c                	lw	a5,32(s1)
    80004298:	37fd                	addiw	a5,a5,-1
    8000429a:	0007891b          	sext.w	s2,a5
    8000429e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042a0:	50dc                	lw	a5,36(s1)
    800042a2:	efb9                	bnez	a5,80004300 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042a4:	06091663          	bnez	s2,80004310 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042a8:	0001d497          	auipc	s1,0x1d
    800042ac:	83848493          	addi	s1,s1,-1992 # 80020ae0 <log>
    800042b0:	4785                	li	a5,1
    800042b2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042b4:	8526                	mv	a0,s1
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	9e8080e7          	jalr	-1560(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042be:	54dc                	lw	a5,44(s1)
    800042c0:	06f04763          	bgtz	a5,8000432e <end_op+0xbc>
    acquire(&log.lock);
    800042c4:	0001d497          	auipc	s1,0x1d
    800042c8:	81c48493          	addi	s1,s1,-2020 # 80020ae0 <log>
    800042cc:	8526                	mv	a0,s1
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	91c080e7          	jalr	-1764(ra) # 80000bea <acquire>
    log.committing = 0;
    800042d6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042da:	8526                	mv	a0,s1
    800042dc:	ffffe097          	auipc	ra,0xffffe
    800042e0:	fac080e7          	jalr	-84(ra) # 80002288 <wakeup>
    release(&log.lock);
    800042e4:	8526                	mv	a0,s1
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	9b8080e7          	jalr	-1608(ra) # 80000c9e <release>
}
    800042ee:	70e2                	ld	ra,56(sp)
    800042f0:	7442                	ld	s0,48(sp)
    800042f2:	74a2                	ld	s1,40(sp)
    800042f4:	7902                	ld	s2,32(sp)
    800042f6:	69e2                	ld	s3,24(sp)
    800042f8:	6a42                	ld	s4,16(sp)
    800042fa:	6aa2                	ld	s5,8(sp)
    800042fc:	6121                	addi	sp,sp,64
    800042fe:	8082                	ret
    panic("log.committing");
    80004300:	00004517          	auipc	a0,0x4
    80004304:	2e850513          	addi	a0,a0,744 # 800085e8 <syscalls+0x1e0>
    80004308:	ffffc097          	auipc	ra,0xffffc
    8000430c:	23c080e7          	jalr	572(ra) # 80000544 <panic>
    wakeup(&log);
    80004310:	0001c497          	auipc	s1,0x1c
    80004314:	7d048493          	addi	s1,s1,2000 # 80020ae0 <log>
    80004318:	8526                	mv	a0,s1
    8000431a:	ffffe097          	auipc	ra,0xffffe
    8000431e:	f6e080e7          	jalr	-146(ra) # 80002288 <wakeup>
  release(&log.lock);
    80004322:	8526                	mv	a0,s1
    80004324:	ffffd097          	auipc	ra,0xffffd
    80004328:	97a080e7          	jalr	-1670(ra) # 80000c9e <release>
  if(do_commit){
    8000432c:	b7c9                	j	800042ee <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000432e:	0001ca97          	auipc	s5,0x1c
    80004332:	7e2a8a93          	addi	s5,s5,2018 # 80020b10 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004336:	0001ca17          	auipc	s4,0x1c
    8000433a:	7aaa0a13          	addi	s4,s4,1962 # 80020ae0 <log>
    8000433e:	018a2583          	lw	a1,24(s4)
    80004342:	012585bb          	addw	a1,a1,s2
    80004346:	2585                	addiw	a1,a1,1
    80004348:	028a2503          	lw	a0,40(s4)
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	cca080e7          	jalr	-822(ra) # 80003016 <bread>
    80004354:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004356:	000aa583          	lw	a1,0(s5)
    8000435a:	028a2503          	lw	a0,40(s4)
    8000435e:	fffff097          	auipc	ra,0xfffff
    80004362:	cb8080e7          	jalr	-840(ra) # 80003016 <bread>
    80004366:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004368:	40000613          	li	a2,1024
    8000436c:	05850593          	addi	a1,a0,88
    80004370:	05848513          	addi	a0,s1,88
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	9d2080e7          	jalr	-1582(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    8000437c:	8526                	mv	a0,s1
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	d8a080e7          	jalr	-630(ra) # 80003108 <bwrite>
    brelse(from);
    80004386:	854e                	mv	a0,s3
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	dbe080e7          	jalr	-578(ra) # 80003146 <brelse>
    brelse(to);
    80004390:	8526                	mv	a0,s1
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	db4080e7          	jalr	-588(ra) # 80003146 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000439a:	2905                	addiw	s2,s2,1
    8000439c:	0a91                	addi	s5,s5,4
    8000439e:	02ca2783          	lw	a5,44(s4)
    800043a2:	f8f94ee3          	blt	s2,a5,8000433e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	c6a080e7          	jalr	-918(ra) # 80004010 <write_head>
    install_trans(0); // Now install writes to home locations
    800043ae:	4501                	li	a0,0
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	cda080e7          	jalr	-806(ra) # 8000408a <install_trans>
    log.lh.n = 0;
    800043b8:	0001c797          	auipc	a5,0x1c
    800043bc:	7407aa23          	sw	zero,1876(a5) # 80020b0c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043c0:	00000097          	auipc	ra,0x0
    800043c4:	c50080e7          	jalr	-944(ra) # 80004010 <write_head>
    800043c8:	bdf5                	j	800042c4 <end_op+0x52>

00000000800043ca <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	e426                	sd	s1,8(sp)
    800043d2:	e04a                	sd	s2,0(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043d8:	0001c917          	auipc	s2,0x1c
    800043dc:	70890913          	addi	s2,s2,1800 # 80020ae0 <log>
    800043e0:	854a                	mv	a0,s2
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	808080e7          	jalr	-2040(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043ea:	02c92603          	lw	a2,44(s2)
    800043ee:	47f5                	li	a5,29
    800043f0:	06c7c563          	blt	a5,a2,8000445a <log_write+0x90>
    800043f4:	0001c797          	auipc	a5,0x1c
    800043f8:	7087a783          	lw	a5,1800(a5) # 80020afc <log+0x1c>
    800043fc:	37fd                	addiw	a5,a5,-1
    800043fe:	04f65e63          	bge	a2,a5,8000445a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004402:	0001c797          	auipc	a5,0x1c
    80004406:	6fe7a783          	lw	a5,1790(a5) # 80020b00 <log+0x20>
    8000440a:	06f05063          	blez	a5,8000446a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000440e:	4781                	li	a5,0
    80004410:	06c05563          	blez	a2,8000447a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004414:	44cc                	lw	a1,12(s1)
    80004416:	0001c717          	auipc	a4,0x1c
    8000441a:	6fa70713          	addi	a4,a4,1786 # 80020b10 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000441e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004420:	4314                	lw	a3,0(a4)
    80004422:	04b68c63          	beq	a3,a1,8000447a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004426:	2785                	addiw	a5,a5,1
    80004428:	0711                	addi	a4,a4,4
    8000442a:	fef61be3          	bne	a2,a5,80004420 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000442e:	0621                	addi	a2,a2,8
    80004430:	060a                	slli	a2,a2,0x2
    80004432:	0001c797          	auipc	a5,0x1c
    80004436:	6ae78793          	addi	a5,a5,1710 # 80020ae0 <log>
    8000443a:	963e                	add	a2,a2,a5
    8000443c:	44dc                	lw	a5,12(s1)
    8000443e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004440:	8526                	mv	a0,s1
    80004442:	fffff097          	auipc	ra,0xfffff
    80004446:	da2080e7          	jalr	-606(ra) # 800031e4 <bpin>
    log.lh.n++;
    8000444a:	0001c717          	auipc	a4,0x1c
    8000444e:	69670713          	addi	a4,a4,1686 # 80020ae0 <log>
    80004452:	575c                	lw	a5,44(a4)
    80004454:	2785                	addiw	a5,a5,1
    80004456:	d75c                	sw	a5,44(a4)
    80004458:	a835                	j	80004494 <log_write+0xca>
    panic("too big a transaction");
    8000445a:	00004517          	auipc	a0,0x4
    8000445e:	19e50513          	addi	a0,a0,414 # 800085f8 <syscalls+0x1f0>
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	0e2080e7          	jalr	226(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000446a:	00004517          	auipc	a0,0x4
    8000446e:	1a650513          	addi	a0,a0,422 # 80008610 <syscalls+0x208>
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	0d2080e7          	jalr	210(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000447a:	00878713          	addi	a4,a5,8
    8000447e:	00271693          	slli	a3,a4,0x2
    80004482:	0001c717          	auipc	a4,0x1c
    80004486:	65e70713          	addi	a4,a4,1630 # 80020ae0 <log>
    8000448a:	9736                	add	a4,a4,a3
    8000448c:	44d4                	lw	a3,12(s1)
    8000448e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004490:	faf608e3          	beq	a2,a5,80004440 <log_write+0x76>
  }
  release(&log.lock);
    80004494:	0001c517          	auipc	a0,0x1c
    80004498:	64c50513          	addi	a0,a0,1612 # 80020ae0 <log>
    8000449c:	ffffd097          	auipc	ra,0xffffd
    800044a0:	802080e7          	jalr	-2046(ra) # 80000c9e <release>
}
    800044a4:	60e2                	ld	ra,24(sp)
    800044a6:	6442                	ld	s0,16(sp)
    800044a8:	64a2                	ld	s1,8(sp)
    800044aa:	6902                	ld	s2,0(sp)
    800044ac:	6105                	addi	sp,sp,32
    800044ae:	8082                	ret

00000000800044b0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044b0:	1101                	addi	sp,sp,-32
    800044b2:	ec06                	sd	ra,24(sp)
    800044b4:	e822                	sd	s0,16(sp)
    800044b6:	e426                	sd	s1,8(sp)
    800044b8:	e04a                	sd	s2,0(sp)
    800044ba:	1000                	addi	s0,sp,32
    800044bc:	84aa                	mv	s1,a0
    800044be:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044c0:	00004597          	auipc	a1,0x4
    800044c4:	17058593          	addi	a1,a1,368 # 80008630 <syscalls+0x228>
    800044c8:	0521                	addi	a0,a0,8
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	690080e7          	jalr	1680(ra) # 80000b5a <initlock>
  lk->name = name;
    800044d2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044d6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044da:	0204a423          	sw	zero,40(s1)
}
    800044de:	60e2                	ld	ra,24(sp)
    800044e0:	6442                	ld	s0,16(sp)
    800044e2:	64a2                	ld	s1,8(sp)
    800044e4:	6902                	ld	s2,0(sp)
    800044e6:	6105                	addi	sp,sp,32
    800044e8:	8082                	ret

00000000800044ea <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044ea:	1101                	addi	sp,sp,-32
    800044ec:	ec06                	sd	ra,24(sp)
    800044ee:	e822                	sd	s0,16(sp)
    800044f0:	e426                	sd	s1,8(sp)
    800044f2:	e04a                	sd	s2,0(sp)
    800044f4:	1000                	addi	s0,sp,32
    800044f6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044f8:	00850913          	addi	s2,a0,8
    800044fc:	854a                	mv	a0,s2
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	6ec080e7          	jalr	1772(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004506:	409c                	lw	a5,0(s1)
    80004508:	cb89                	beqz	a5,8000451a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000450a:	85ca                	mv	a1,s2
    8000450c:	8526                	mv	a0,s1
    8000450e:	ffffe097          	auipc	ra,0xffffe
    80004512:	d16080e7          	jalr	-746(ra) # 80002224 <sleep>
  while (lk->locked) {
    80004516:	409c                	lw	a5,0(s1)
    80004518:	fbed                	bnez	a5,8000450a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000451a:	4785                	li	a5,1
    8000451c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000451e:	ffffd097          	auipc	ra,0xffffd
    80004522:	5f6080e7          	jalr	1526(ra) # 80001b14 <myproc>
    80004526:	591c                	lw	a5,48(a0)
    80004528:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000452a:	854a                	mv	a0,s2
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	772080e7          	jalr	1906(ra) # 80000c9e <release>
}
    80004534:	60e2                	ld	ra,24(sp)
    80004536:	6442                	ld	s0,16(sp)
    80004538:	64a2                	ld	s1,8(sp)
    8000453a:	6902                	ld	s2,0(sp)
    8000453c:	6105                	addi	sp,sp,32
    8000453e:	8082                	ret

0000000080004540 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004540:	1101                	addi	sp,sp,-32
    80004542:	ec06                	sd	ra,24(sp)
    80004544:	e822                	sd	s0,16(sp)
    80004546:	e426                	sd	s1,8(sp)
    80004548:	e04a                	sd	s2,0(sp)
    8000454a:	1000                	addi	s0,sp,32
    8000454c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000454e:	00850913          	addi	s2,a0,8
    80004552:	854a                	mv	a0,s2
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	696080e7          	jalr	1686(ra) # 80000bea <acquire>
  lk->locked = 0;
    8000455c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004560:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004564:	8526                	mv	a0,s1
    80004566:	ffffe097          	auipc	ra,0xffffe
    8000456a:	d22080e7          	jalr	-734(ra) # 80002288 <wakeup>
  release(&lk->lk);
    8000456e:	854a                	mv	a0,s2
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	72e080e7          	jalr	1838(ra) # 80000c9e <release>
}
    80004578:	60e2                	ld	ra,24(sp)
    8000457a:	6442                	ld	s0,16(sp)
    8000457c:	64a2                	ld	s1,8(sp)
    8000457e:	6902                	ld	s2,0(sp)
    80004580:	6105                	addi	sp,sp,32
    80004582:	8082                	ret

0000000080004584 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004584:	7179                	addi	sp,sp,-48
    80004586:	f406                	sd	ra,40(sp)
    80004588:	f022                	sd	s0,32(sp)
    8000458a:	ec26                	sd	s1,24(sp)
    8000458c:	e84a                	sd	s2,16(sp)
    8000458e:	e44e                	sd	s3,8(sp)
    80004590:	1800                	addi	s0,sp,48
    80004592:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004594:	00850913          	addi	s2,a0,8
    80004598:	854a                	mv	a0,s2
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	650080e7          	jalr	1616(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045a2:	409c                	lw	a5,0(s1)
    800045a4:	ef99                	bnez	a5,800045c2 <holdingsleep+0x3e>
    800045a6:	4481                	li	s1,0
  release(&lk->lk);
    800045a8:	854a                	mv	a0,s2
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	6f4080e7          	jalr	1780(ra) # 80000c9e <release>
  return r;
}
    800045b2:	8526                	mv	a0,s1
    800045b4:	70a2                	ld	ra,40(sp)
    800045b6:	7402                	ld	s0,32(sp)
    800045b8:	64e2                	ld	s1,24(sp)
    800045ba:	6942                	ld	s2,16(sp)
    800045bc:	69a2                	ld	s3,8(sp)
    800045be:	6145                	addi	sp,sp,48
    800045c0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c2:	0284a983          	lw	s3,40(s1)
    800045c6:	ffffd097          	auipc	ra,0xffffd
    800045ca:	54e080e7          	jalr	1358(ra) # 80001b14 <myproc>
    800045ce:	5904                	lw	s1,48(a0)
    800045d0:	413484b3          	sub	s1,s1,s3
    800045d4:	0014b493          	seqz	s1,s1
    800045d8:	bfc1                	j	800045a8 <holdingsleep+0x24>

00000000800045da <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045da:	1141                	addi	sp,sp,-16
    800045dc:	e406                	sd	ra,8(sp)
    800045de:	e022                	sd	s0,0(sp)
    800045e0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045e2:	00004597          	auipc	a1,0x4
    800045e6:	05e58593          	addi	a1,a1,94 # 80008640 <syscalls+0x238>
    800045ea:	0001c517          	auipc	a0,0x1c
    800045ee:	63e50513          	addi	a0,a0,1598 # 80020c28 <ftable>
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	568080e7          	jalr	1384(ra) # 80000b5a <initlock>
}
    800045fa:	60a2                	ld	ra,8(sp)
    800045fc:	6402                	ld	s0,0(sp)
    800045fe:	0141                	addi	sp,sp,16
    80004600:	8082                	ret

0000000080004602 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004602:	1101                	addi	sp,sp,-32
    80004604:	ec06                	sd	ra,24(sp)
    80004606:	e822                	sd	s0,16(sp)
    80004608:	e426                	sd	s1,8(sp)
    8000460a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000460c:	0001c517          	auipc	a0,0x1c
    80004610:	61c50513          	addi	a0,a0,1564 # 80020c28 <ftable>
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	5d6080e7          	jalr	1494(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000461c:	0001c497          	auipc	s1,0x1c
    80004620:	62448493          	addi	s1,s1,1572 # 80020c40 <ftable+0x18>
    80004624:	0001d717          	auipc	a4,0x1d
    80004628:	5bc70713          	addi	a4,a4,1468 # 80021be0 <disk>
    if(f->ref == 0){
    8000462c:	40dc                	lw	a5,4(s1)
    8000462e:	cf99                	beqz	a5,8000464c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004630:	02848493          	addi	s1,s1,40
    80004634:	fee49ce3          	bne	s1,a4,8000462c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004638:	0001c517          	auipc	a0,0x1c
    8000463c:	5f050513          	addi	a0,a0,1520 # 80020c28 <ftable>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	65e080e7          	jalr	1630(ra) # 80000c9e <release>
  return 0;
    80004648:	4481                	li	s1,0
    8000464a:	a819                	j	80004660 <filealloc+0x5e>
      f->ref = 1;
    8000464c:	4785                	li	a5,1
    8000464e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004650:	0001c517          	auipc	a0,0x1c
    80004654:	5d850513          	addi	a0,a0,1496 # 80020c28 <ftable>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	646080e7          	jalr	1606(ra) # 80000c9e <release>
}
    80004660:	8526                	mv	a0,s1
    80004662:	60e2                	ld	ra,24(sp)
    80004664:	6442                	ld	s0,16(sp)
    80004666:	64a2                	ld	s1,8(sp)
    80004668:	6105                	addi	sp,sp,32
    8000466a:	8082                	ret

000000008000466c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000466c:	1101                	addi	sp,sp,-32
    8000466e:	ec06                	sd	ra,24(sp)
    80004670:	e822                	sd	s0,16(sp)
    80004672:	e426                	sd	s1,8(sp)
    80004674:	1000                	addi	s0,sp,32
    80004676:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004678:	0001c517          	auipc	a0,0x1c
    8000467c:	5b050513          	addi	a0,a0,1456 # 80020c28 <ftable>
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	56a080e7          	jalr	1386(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004688:	40dc                	lw	a5,4(s1)
    8000468a:	02f05263          	blez	a5,800046ae <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000468e:	2785                	addiw	a5,a5,1
    80004690:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004692:	0001c517          	auipc	a0,0x1c
    80004696:	59650513          	addi	a0,a0,1430 # 80020c28 <ftable>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	604080e7          	jalr	1540(ra) # 80000c9e <release>
  return f;
}
    800046a2:	8526                	mv	a0,s1
    800046a4:	60e2                	ld	ra,24(sp)
    800046a6:	6442                	ld	s0,16(sp)
    800046a8:	64a2                	ld	s1,8(sp)
    800046aa:	6105                	addi	sp,sp,32
    800046ac:	8082                	ret
    panic("filedup");
    800046ae:	00004517          	auipc	a0,0x4
    800046b2:	f9a50513          	addi	a0,a0,-102 # 80008648 <syscalls+0x240>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	e8e080e7          	jalr	-370(ra) # 80000544 <panic>

00000000800046be <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046be:	7139                	addi	sp,sp,-64
    800046c0:	fc06                	sd	ra,56(sp)
    800046c2:	f822                	sd	s0,48(sp)
    800046c4:	f426                	sd	s1,40(sp)
    800046c6:	f04a                	sd	s2,32(sp)
    800046c8:	ec4e                	sd	s3,24(sp)
    800046ca:	e852                	sd	s4,16(sp)
    800046cc:	e456                	sd	s5,8(sp)
    800046ce:	0080                	addi	s0,sp,64
    800046d0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046d2:	0001c517          	auipc	a0,0x1c
    800046d6:	55650513          	addi	a0,a0,1366 # 80020c28 <ftable>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	510080e7          	jalr	1296(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800046e2:	40dc                	lw	a5,4(s1)
    800046e4:	06f05163          	blez	a5,80004746 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046e8:	37fd                	addiw	a5,a5,-1
    800046ea:	0007871b          	sext.w	a4,a5
    800046ee:	c0dc                	sw	a5,4(s1)
    800046f0:	06e04363          	bgtz	a4,80004756 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046f4:	0004a903          	lw	s2,0(s1)
    800046f8:	0094ca83          	lbu	s5,9(s1)
    800046fc:	0104ba03          	ld	s4,16(s1)
    80004700:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004704:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004708:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000470c:	0001c517          	auipc	a0,0x1c
    80004710:	51c50513          	addi	a0,a0,1308 # 80020c28 <ftable>
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	58a080e7          	jalr	1418(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    8000471c:	4785                	li	a5,1
    8000471e:	04f90d63          	beq	s2,a5,80004778 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004722:	3979                	addiw	s2,s2,-2
    80004724:	4785                	li	a5,1
    80004726:	0527e063          	bltu	a5,s2,80004766 <fileclose+0xa8>
    begin_op();
    8000472a:	00000097          	auipc	ra,0x0
    8000472e:	ac8080e7          	jalr	-1336(ra) # 800041f2 <begin_op>
    iput(ff.ip);
    80004732:	854e                	mv	a0,s3
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	2b6080e7          	jalr	694(ra) # 800039ea <iput>
    end_op();
    8000473c:	00000097          	auipc	ra,0x0
    80004740:	b36080e7          	jalr	-1226(ra) # 80004272 <end_op>
    80004744:	a00d                	j	80004766 <fileclose+0xa8>
    panic("fileclose");
    80004746:	00004517          	auipc	a0,0x4
    8000474a:	f0a50513          	addi	a0,a0,-246 # 80008650 <syscalls+0x248>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	df6080e7          	jalr	-522(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004756:	0001c517          	auipc	a0,0x1c
    8000475a:	4d250513          	addi	a0,a0,1234 # 80020c28 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	540080e7          	jalr	1344(ra) # 80000c9e <release>
  }
}
    80004766:	70e2                	ld	ra,56(sp)
    80004768:	7442                	ld	s0,48(sp)
    8000476a:	74a2                	ld	s1,40(sp)
    8000476c:	7902                	ld	s2,32(sp)
    8000476e:	69e2                	ld	s3,24(sp)
    80004770:	6a42                	ld	s4,16(sp)
    80004772:	6aa2                	ld	s5,8(sp)
    80004774:	6121                	addi	sp,sp,64
    80004776:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004778:	85d6                	mv	a1,s5
    8000477a:	8552                	mv	a0,s4
    8000477c:	00000097          	auipc	ra,0x0
    80004780:	34c080e7          	jalr	844(ra) # 80004ac8 <pipeclose>
    80004784:	b7cd                	j	80004766 <fileclose+0xa8>

0000000080004786 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004786:	715d                	addi	sp,sp,-80
    80004788:	e486                	sd	ra,72(sp)
    8000478a:	e0a2                	sd	s0,64(sp)
    8000478c:	fc26                	sd	s1,56(sp)
    8000478e:	f84a                	sd	s2,48(sp)
    80004790:	f44e                	sd	s3,40(sp)
    80004792:	0880                	addi	s0,sp,80
    80004794:	84aa                	mv	s1,a0
    80004796:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004798:	ffffd097          	auipc	ra,0xffffd
    8000479c:	37c080e7          	jalr	892(ra) # 80001b14 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047a0:	409c                	lw	a5,0(s1)
    800047a2:	37f9                	addiw	a5,a5,-2
    800047a4:	4705                	li	a4,1
    800047a6:	04f76763          	bltu	a4,a5,800047f4 <filestat+0x6e>
    800047aa:	892a                	mv	s2,a0
    ilock(f->ip);
    800047ac:	6c88                	ld	a0,24(s1)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	082080e7          	jalr	130(ra) # 80003830 <ilock>
    stati(f->ip, &st);
    800047b6:	fb840593          	addi	a1,s0,-72
    800047ba:	6c88                	ld	a0,24(s1)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	2fe080e7          	jalr	766(ra) # 80003aba <stati>
    iunlock(f->ip);
    800047c4:	6c88                	ld	a0,24(s1)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	12c080e7          	jalr	300(ra) # 800038f2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047ce:	46e1                	li	a3,24
    800047d0:	fb840613          	addi	a2,s0,-72
    800047d4:	85ce                	mv	a1,s3
    800047d6:	05093503          	ld	a0,80(s2)
    800047da:	ffffd097          	auipc	ra,0xffffd
    800047de:	ff8080e7          	jalr	-8(ra) # 800017d2 <copyout>
    800047e2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047e6:	60a6                	ld	ra,72(sp)
    800047e8:	6406                	ld	s0,64(sp)
    800047ea:	74e2                	ld	s1,56(sp)
    800047ec:	7942                	ld	s2,48(sp)
    800047ee:	79a2                	ld	s3,40(sp)
    800047f0:	6161                	addi	sp,sp,80
    800047f2:	8082                	ret
  return -1;
    800047f4:	557d                	li	a0,-1
    800047f6:	bfc5                	j	800047e6 <filestat+0x60>

00000000800047f8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047f8:	7179                	addi	sp,sp,-48
    800047fa:	f406                	sd	ra,40(sp)
    800047fc:	f022                	sd	s0,32(sp)
    800047fe:	ec26                	sd	s1,24(sp)
    80004800:	e84a                	sd	s2,16(sp)
    80004802:	e44e                	sd	s3,8(sp)
    80004804:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004806:	00854783          	lbu	a5,8(a0)
    8000480a:	c3d5                	beqz	a5,800048ae <fileread+0xb6>
    8000480c:	84aa                	mv	s1,a0
    8000480e:	89ae                	mv	s3,a1
    80004810:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004812:	411c                	lw	a5,0(a0)
    80004814:	4705                	li	a4,1
    80004816:	04e78963          	beq	a5,a4,80004868 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000481a:	470d                	li	a4,3
    8000481c:	04e78d63          	beq	a5,a4,80004876 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004820:	4709                	li	a4,2
    80004822:	06e79e63          	bne	a5,a4,8000489e <fileread+0xa6>
    ilock(f->ip);
    80004826:	6d08                	ld	a0,24(a0)
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	008080e7          	jalr	8(ra) # 80003830 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004830:	874a                	mv	a4,s2
    80004832:	5094                	lw	a3,32(s1)
    80004834:	864e                	mv	a2,s3
    80004836:	4585                	li	a1,1
    80004838:	6c88                	ld	a0,24(s1)
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	2aa080e7          	jalr	682(ra) # 80003ae4 <readi>
    80004842:	892a                	mv	s2,a0
    80004844:	00a05563          	blez	a0,8000484e <fileread+0x56>
      f->off += r;
    80004848:	509c                	lw	a5,32(s1)
    8000484a:	9fa9                	addw	a5,a5,a0
    8000484c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000484e:	6c88                	ld	a0,24(s1)
    80004850:	fffff097          	auipc	ra,0xfffff
    80004854:	0a2080e7          	jalr	162(ra) # 800038f2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004858:	854a                	mv	a0,s2
    8000485a:	70a2                	ld	ra,40(sp)
    8000485c:	7402                	ld	s0,32(sp)
    8000485e:	64e2                	ld	s1,24(sp)
    80004860:	6942                	ld	s2,16(sp)
    80004862:	69a2                	ld	s3,8(sp)
    80004864:	6145                	addi	sp,sp,48
    80004866:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004868:	6908                	ld	a0,16(a0)
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	3ce080e7          	jalr	974(ra) # 80004c38 <piperead>
    80004872:	892a                	mv	s2,a0
    80004874:	b7d5                	j	80004858 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004876:	02451783          	lh	a5,36(a0)
    8000487a:	03079693          	slli	a3,a5,0x30
    8000487e:	92c1                	srli	a3,a3,0x30
    80004880:	4725                	li	a4,9
    80004882:	02d76863          	bltu	a4,a3,800048b2 <fileread+0xba>
    80004886:	0792                	slli	a5,a5,0x4
    80004888:	0001c717          	auipc	a4,0x1c
    8000488c:	30070713          	addi	a4,a4,768 # 80020b88 <devsw>
    80004890:	97ba                	add	a5,a5,a4
    80004892:	639c                	ld	a5,0(a5)
    80004894:	c38d                	beqz	a5,800048b6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004896:	4505                	li	a0,1
    80004898:	9782                	jalr	a5
    8000489a:	892a                	mv	s2,a0
    8000489c:	bf75                	j	80004858 <fileread+0x60>
    panic("fileread");
    8000489e:	00004517          	auipc	a0,0x4
    800048a2:	dc250513          	addi	a0,a0,-574 # 80008660 <syscalls+0x258>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	c9e080e7          	jalr	-866(ra) # 80000544 <panic>
    return -1;
    800048ae:	597d                	li	s2,-1
    800048b0:	b765                	j	80004858 <fileread+0x60>
      return -1;
    800048b2:	597d                	li	s2,-1
    800048b4:	b755                	j	80004858 <fileread+0x60>
    800048b6:	597d                	li	s2,-1
    800048b8:	b745                	j	80004858 <fileread+0x60>

00000000800048ba <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048ba:	715d                	addi	sp,sp,-80
    800048bc:	e486                	sd	ra,72(sp)
    800048be:	e0a2                	sd	s0,64(sp)
    800048c0:	fc26                	sd	s1,56(sp)
    800048c2:	f84a                	sd	s2,48(sp)
    800048c4:	f44e                	sd	s3,40(sp)
    800048c6:	f052                	sd	s4,32(sp)
    800048c8:	ec56                	sd	s5,24(sp)
    800048ca:	e85a                	sd	s6,16(sp)
    800048cc:	e45e                	sd	s7,8(sp)
    800048ce:	e062                	sd	s8,0(sp)
    800048d0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048d2:	00954783          	lbu	a5,9(a0)
    800048d6:	10078663          	beqz	a5,800049e2 <filewrite+0x128>
    800048da:	892a                	mv	s2,a0
    800048dc:	8aae                	mv	s5,a1
    800048de:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e0:	411c                	lw	a5,0(a0)
    800048e2:	4705                	li	a4,1
    800048e4:	02e78263          	beq	a5,a4,80004908 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048e8:	470d                	li	a4,3
    800048ea:	02e78663          	beq	a5,a4,80004916 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048ee:	4709                	li	a4,2
    800048f0:	0ee79163          	bne	a5,a4,800049d2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048f4:	0ac05d63          	blez	a2,800049ae <filewrite+0xf4>
    int i = 0;
    800048f8:	4981                	li	s3,0
    800048fa:	6b05                	lui	s6,0x1
    800048fc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004900:	6b85                	lui	s7,0x1
    80004902:	c00b8b9b          	addiw	s7,s7,-1024
    80004906:	a861                	j	8000499e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004908:	6908                	ld	a0,16(a0)
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	22e080e7          	jalr	558(ra) # 80004b38 <pipewrite>
    80004912:	8a2a                	mv	s4,a0
    80004914:	a045                	j	800049b4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004916:	02451783          	lh	a5,36(a0)
    8000491a:	03079693          	slli	a3,a5,0x30
    8000491e:	92c1                	srli	a3,a3,0x30
    80004920:	4725                	li	a4,9
    80004922:	0cd76263          	bltu	a4,a3,800049e6 <filewrite+0x12c>
    80004926:	0792                	slli	a5,a5,0x4
    80004928:	0001c717          	auipc	a4,0x1c
    8000492c:	26070713          	addi	a4,a4,608 # 80020b88 <devsw>
    80004930:	97ba                	add	a5,a5,a4
    80004932:	679c                	ld	a5,8(a5)
    80004934:	cbdd                	beqz	a5,800049ea <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004936:	4505                	li	a0,1
    80004938:	9782                	jalr	a5
    8000493a:	8a2a                	mv	s4,a0
    8000493c:	a8a5                	j	800049b4 <filewrite+0xfa>
    8000493e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004942:	00000097          	auipc	ra,0x0
    80004946:	8b0080e7          	jalr	-1872(ra) # 800041f2 <begin_op>
      ilock(f->ip);
    8000494a:	01893503          	ld	a0,24(s2)
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	ee2080e7          	jalr	-286(ra) # 80003830 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004956:	8762                	mv	a4,s8
    80004958:	02092683          	lw	a3,32(s2)
    8000495c:	01598633          	add	a2,s3,s5
    80004960:	4585                	li	a1,1
    80004962:	01893503          	ld	a0,24(s2)
    80004966:	fffff097          	auipc	ra,0xfffff
    8000496a:	276080e7          	jalr	630(ra) # 80003bdc <writei>
    8000496e:	84aa                	mv	s1,a0
    80004970:	00a05763          	blez	a0,8000497e <filewrite+0xc4>
        f->off += r;
    80004974:	02092783          	lw	a5,32(s2)
    80004978:	9fa9                	addw	a5,a5,a0
    8000497a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000497e:	01893503          	ld	a0,24(s2)
    80004982:	fffff097          	auipc	ra,0xfffff
    80004986:	f70080e7          	jalr	-144(ra) # 800038f2 <iunlock>
      end_op();
    8000498a:	00000097          	auipc	ra,0x0
    8000498e:	8e8080e7          	jalr	-1816(ra) # 80004272 <end_op>

      if(r != n1){
    80004992:	009c1f63          	bne	s8,s1,800049b0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004996:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000499a:	0149db63          	bge	s3,s4,800049b0 <filewrite+0xf6>
      int n1 = n - i;
    8000499e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049a2:	84be                	mv	s1,a5
    800049a4:	2781                	sext.w	a5,a5
    800049a6:	f8fb5ce3          	bge	s6,a5,8000493e <filewrite+0x84>
    800049aa:	84de                	mv	s1,s7
    800049ac:	bf49                	j	8000493e <filewrite+0x84>
    int i = 0;
    800049ae:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049b0:	013a1f63          	bne	s4,s3,800049ce <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049b4:	8552                	mv	a0,s4
    800049b6:	60a6                	ld	ra,72(sp)
    800049b8:	6406                	ld	s0,64(sp)
    800049ba:	74e2                	ld	s1,56(sp)
    800049bc:	7942                	ld	s2,48(sp)
    800049be:	79a2                	ld	s3,40(sp)
    800049c0:	7a02                	ld	s4,32(sp)
    800049c2:	6ae2                	ld	s5,24(sp)
    800049c4:	6b42                	ld	s6,16(sp)
    800049c6:	6ba2                	ld	s7,8(sp)
    800049c8:	6c02                	ld	s8,0(sp)
    800049ca:	6161                	addi	sp,sp,80
    800049cc:	8082                	ret
    ret = (i == n ? n : -1);
    800049ce:	5a7d                	li	s4,-1
    800049d0:	b7d5                	j	800049b4 <filewrite+0xfa>
    panic("filewrite");
    800049d2:	00004517          	auipc	a0,0x4
    800049d6:	c9e50513          	addi	a0,a0,-866 # 80008670 <syscalls+0x268>
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	b6a080e7          	jalr	-1174(ra) # 80000544 <panic>
    return -1;
    800049e2:	5a7d                	li	s4,-1
    800049e4:	bfc1                	j	800049b4 <filewrite+0xfa>
      return -1;
    800049e6:	5a7d                	li	s4,-1
    800049e8:	b7f1                	j	800049b4 <filewrite+0xfa>
    800049ea:	5a7d                	li	s4,-1
    800049ec:	b7e1                	j	800049b4 <filewrite+0xfa>

00000000800049ee <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049ee:	7179                	addi	sp,sp,-48
    800049f0:	f406                	sd	ra,40(sp)
    800049f2:	f022                	sd	s0,32(sp)
    800049f4:	ec26                	sd	s1,24(sp)
    800049f6:	e84a                	sd	s2,16(sp)
    800049f8:	e44e                	sd	s3,8(sp)
    800049fa:	e052                	sd	s4,0(sp)
    800049fc:	1800                	addi	s0,sp,48
    800049fe:	84aa                	mv	s1,a0
    80004a00:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a02:	0005b023          	sd	zero,0(a1)
    80004a06:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a0a:	00000097          	auipc	ra,0x0
    80004a0e:	bf8080e7          	jalr	-1032(ra) # 80004602 <filealloc>
    80004a12:	e088                	sd	a0,0(s1)
    80004a14:	c551                	beqz	a0,80004aa0 <pipealloc+0xb2>
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	bec080e7          	jalr	-1044(ra) # 80004602 <filealloc>
    80004a1e:	00aa3023          	sd	a0,0(s4)
    80004a22:	c92d                	beqz	a0,80004a94 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	0d6080e7          	jalr	214(ra) # 80000afa <kalloc>
    80004a2c:	892a                	mv	s2,a0
    80004a2e:	c125                	beqz	a0,80004a8e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a30:	4985                	li	s3,1
    80004a32:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a36:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a3a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a3e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a42:	00004597          	auipc	a1,0x4
    80004a46:	c3e58593          	addi	a1,a1,-962 # 80008680 <syscalls+0x278>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	110080e7          	jalr	272(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004a52:	609c                	ld	a5,0(s1)
    80004a54:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a58:	609c                	ld	a5,0(s1)
    80004a5a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a5e:	609c                	ld	a5,0(s1)
    80004a60:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a64:	609c                	ld	a5,0(s1)
    80004a66:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a6a:	000a3783          	ld	a5,0(s4)
    80004a6e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a72:	000a3783          	ld	a5,0(s4)
    80004a76:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a7a:	000a3783          	ld	a5,0(s4)
    80004a7e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a82:	000a3783          	ld	a5,0(s4)
    80004a86:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a8a:	4501                	li	a0,0
    80004a8c:	a025                	j	80004ab4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a8e:	6088                	ld	a0,0(s1)
    80004a90:	e501                	bnez	a0,80004a98 <pipealloc+0xaa>
    80004a92:	a039                	j	80004aa0 <pipealloc+0xb2>
    80004a94:	6088                	ld	a0,0(s1)
    80004a96:	c51d                	beqz	a0,80004ac4 <pipealloc+0xd6>
    fileclose(*f0);
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	c26080e7          	jalr	-986(ra) # 800046be <fileclose>
  if(*f1)
    80004aa0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004aa4:	557d                	li	a0,-1
  if(*f1)
    80004aa6:	c799                	beqz	a5,80004ab4 <pipealloc+0xc6>
    fileclose(*f1);
    80004aa8:	853e                	mv	a0,a5
    80004aaa:	00000097          	auipc	ra,0x0
    80004aae:	c14080e7          	jalr	-1004(ra) # 800046be <fileclose>
  return -1;
    80004ab2:	557d                	li	a0,-1
}
    80004ab4:	70a2                	ld	ra,40(sp)
    80004ab6:	7402                	ld	s0,32(sp)
    80004ab8:	64e2                	ld	s1,24(sp)
    80004aba:	6942                	ld	s2,16(sp)
    80004abc:	69a2                	ld	s3,8(sp)
    80004abe:	6a02                	ld	s4,0(sp)
    80004ac0:	6145                	addi	sp,sp,48
    80004ac2:	8082                	ret
  return -1;
    80004ac4:	557d                	li	a0,-1
    80004ac6:	b7fd                	j	80004ab4 <pipealloc+0xc6>

0000000080004ac8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ac8:	1101                	addi	sp,sp,-32
    80004aca:	ec06                	sd	ra,24(sp)
    80004acc:	e822                	sd	s0,16(sp)
    80004ace:	e426                	sd	s1,8(sp)
    80004ad0:	e04a                	sd	s2,0(sp)
    80004ad2:	1000                	addi	s0,sp,32
    80004ad4:	84aa                	mv	s1,a0
    80004ad6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	112080e7          	jalr	274(ra) # 80000bea <acquire>
  if(writable){
    80004ae0:	02090d63          	beqz	s2,80004b1a <pipeclose+0x52>
    pi->writeopen = 0;
    80004ae4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ae8:	21848513          	addi	a0,s1,536
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	79c080e7          	jalr	1948(ra) # 80002288 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004af4:	2204b783          	ld	a5,544(s1)
    80004af8:	eb95                	bnez	a5,80004b2c <pipeclose+0x64>
    release(&pi->lock);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	1a2080e7          	jalr	418(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004b04:	8526                	mv	a0,s1
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	ef8080e7          	jalr	-264(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004b0e:	60e2                	ld	ra,24(sp)
    80004b10:	6442                	ld	s0,16(sp)
    80004b12:	64a2                	ld	s1,8(sp)
    80004b14:	6902                	ld	s2,0(sp)
    80004b16:	6105                	addi	sp,sp,32
    80004b18:	8082                	ret
    pi->readopen = 0;
    80004b1a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b1e:	21c48513          	addi	a0,s1,540
    80004b22:	ffffd097          	auipc	ra,0xffffd
    80004b26:	766080e7          	jalr	1894(ra) # 80002288 <wakeup>
    80004b2a:	b7e9                	j	80004af4 <pipeclose+0x2c>
    release(&pi->lock);
    80004b2c:	8526                	mv	a0,s1
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	170080e7          	jalr	368(ra) # 80000c9e <release>
}
    80004b36:	bfe1                	j	80004b0e <pipeclose+0x46>

0000000080004b38 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b38:	7159                	addi	sp,sp,-112
    80004b3a:	f486                	sd	ra,104(sp)
    80004b3c:	f0a2                	sd	s0,96(sp)
    80004b3e:	eca6                	sd	s1,88(sp)
    80004b40:	e8ca                	sd	s2,80(sp)
    80004b42:	e4ce                	sd	s3,72(sp)
    80004b44:	e0d2                	sd	s4,64(sp)
    80004b46:	fc56                	sd	s5,56(sp)
    80004b48:	f85a                	sd	s6,48(sp)
    80004b4a:	f45e                	sd	s7,40(sp)
    80004b4c:	f062                	sd	s8,32(sp)
    80004b4e:	ec66                	sd	s9,24(sp)
    80004b50:	1880                	addi	s0,sp,112
    80004b52:	84aa                	mv	s1,a0
    80004b54:	8aae                	mv	s5,a1
    80004b56:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	fbc080e7          	jalr	-68(ra) # 80001b14 <myproc>
    80004b60:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b62:	8526                	mv	a0,s1
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	086080e7          	jalr	134(ra) # 80000bea <acquire>
  while(i < n){
    80004b6c:	0d405463          	blez	s4,80004c34 <pipewrite+0xfc>
    80004b70:	8ba6                	mv	s7,s1
  int i = 0;
    80004b72:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b74:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b76:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b7a:	21c48c13          	addi	s8,s1,540
    80004b7e:	a08d                	j	80004be0 <pipewrite+0xa8>
      release(&pi->lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	11c080e7          	jalr	284(ra) # 80000c9e <release>
      return -1;
    80004b8a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b8c:	854a                	mv	a0,s2
    80004b8e:	70a6                	ld	ra,104(sp)
    80004b90:	7406                	ld	s0,96(sp)
    80004b92:	64e6                	ld	s1,88(sp)
    80004b94:	6946                	ld	s2,80(sp)
    80004b96:	69a6                	ld	s3,72(sp)
    80004b98:	6a06                	ld	s4,64(sp)
    80004b9a:	7ae2                	ld	s5,56(sp)
    80004b9c:	7b42                	ld	s6,48(sp)
    80004b9e:	7ba2                	ld	s7,40(sp)
    80004ba0:	7c02                	ld	s8,32(sp)
    80004ba2:	6ce2                	ld	s9,24(sp)
    80004ba4:	6165                	addi	sp,sp,112
    80004ba6:	8082                	ret
      wakeup(&pi->nread);
    80004ba8:	8566                	mv	a0,s9
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	6de080e7          	jalr	1758(ra) # 80002288 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bb2:	85de                	mv	a1,s7
    80004bb4:	8562                	mv	a0,s8
    80004bb6:	ffffd097          	auipc	ra,0xffffd
    80004bba:	66e080e7          	jalr	1646(ra) # 80002224 <sleep>
    80004bbe:	a839                	j	80004bdc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc0:	21c4a783          	lw	a5,540(s1)
    80004bc4:	0017871b          	addiw	a4,a5,1
    80004bc8:	20e4ae23          	sw	a4,540(s1)
    80004bcc:	1ff7f793          	andi	a5,a5,511
    80004bd0:	97a6                	add	a5,a5,s1
    80004bd2:	f9f44703          	lbu	a4,-97(s0)
    80004bd6:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bda:	2905                	addiw	s2,s2,1
  while(i < n){
    80004bdc:	05495063          	bge	s2,s4,80004c1c <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004be0:	2204a783          	lw	a5,544(s1)
    80004be4:	dfd1                	beqz	a5,80004b80 <pipewrite+0x48>
    80004be6:	854e                	mv	a0,s3
    80004be8:	ffffe097          	auipc	ra,0xffffe
    80004bec:	8e4080e7          	jalr	-1820(ra) # 800024cc <killed>
    80004bf0:	f941                	bnez	a0,80004b80 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bf2:	2184a783          	lw	a5,536(s1)
    80004bf6:	21c4a703          	lw	a4,540(s1)
    80004bfa:	2007879b          	addiw	a5,a5,512
    80004bfe:	faf705e3          	beq	a4,a5,80004ba8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c02:	4685                	li	a3,1
    80004c04:	01590633          	add	a2,s2,s5
    80004c08:	f9f40593          	addi	a1,s0,-97
    80004c0c:	0509b503          	ld	a0,80(s3)
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	c4e080e7          	jalr	-946(ra) # 8000185e <copyin>
    80004c18:	fb6514e3          	bne	a0,s6,80004bc0 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c1c:	21848513          	addi	a0,s1,536
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	668080e7          	jalr	1640(ra) # 80002288 <wakeup>
  release(&pi->lock);
    80004c28:	8526                	mv	a0,s1
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	074080e7          	jalr	116(ra) # 80000c9e <release>
  return i;
    80004c32:	bfa9                	j	80004b8c <pipewrite+0x54>
  int i = 0;
    80004c34:	4901                	li	s2,0
    80004c36:	b7dd                	j	80004c1c <pipewrite+0xe4>

0000000080004c38 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c38:	715d                	addi	sp,sp,-80
    80004c3a:	e486                	sd	ra,72(sp)
    80004c3c:	e0a2                	sd	s0,64(sp)
    80004c3e:	fc26                	sd	s1,56(sp)
    80004c40:	f84a                	sd	s2,48(sp)
    80004c42:	f44e                	sd	s3,40(sp)
    80004c44:	f052                	sd	s4,32(sp)
    80004c46:	ec56                	sd	s5,24(sp)
    80004c48:	e85a                	sd	s6,16(sp)
    80004c4a:	0880                	addi	s0,sp,80
    80004c4c:	84aa                	mv	s1,a0
    80004c4e:	892e                	mv	s2,a1
    80004c50:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	ec2080e7          	jalr	-318(ra) # 80001b14 <myproc>
    80004c5a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c5c:	8b26                	mv	s6,s1
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	f8a080e7          	jalr	-118(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c68:	2184a703          	lw	a4,536(s1)
    80004c6c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c70:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c74:	02f71763          	bne	a4,a5,80004ca2 <piperead+0x6a>
    80004c78:	2244a783          	lw	a5,548(s1)
    80004c7c:	c39d                	beqz	a5,80004ca2 <piperead+0x6a>
    if(killed(pr)){
    80004c7e:	8552                	mv	a0,s4
    80004c80:	ffffe097          	auipc	ra,0xffffe
    80004c84:	84c080e7          	jalr	-1972(ra) # 800024cc <killed>
    80004c88:	e941                	bnez	a0,80004d18 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c8a:	85da                	mv	a1,s6
    80004c8c:	854e                	mv	a0,s3
    80004c8e:	ffffd097          	auipc	ra,0xffffd
    80004c92:	596080e7          	jalr	1430(ra) # 80002224 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c96:	2184a703          	lw	a4,536(s1)
    80004c9a:	21c4a783          	lw	a5,540(s1)
    80004c9e:	fcf70de3          	beq	a4,a5,80004c78 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca2:	09505263          	blez	s5,80004d26 <piperead+0xee>
    80004ca6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004caa:	2184a783          	lw	a5,536(s1)
    80004cae:	21c4a703          	lw	a4,540(s1)
    80004cb2:	02f70d63          	beq	a4,a5,80004cec <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cb6:	0017871b          	addiw	a4,a5,1
    80004cba:	20e4ac23          	sw	a4,536(s1)
    80004cbe:	1ff7f793          	andi	a5,a5,511
    80004cc2:	97a6                	add	a5,a5,s1
    80004cc4:	0187c783          	lbu	a5,24(a5)
    80004cc8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ccc:	4685                	li	a3,1
    80004cce:	fbf40613          	addi	a2,s0,-65
    80004cd2:	85ca                	mv	a1,s2
    80004cd4:	050a3503          	ld	a0,80(s4)
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	afa080e7          	jalr	-1286(ra) # 800017d2 <copyout>
    80004ce0:	01650663          	beq	a0,s6,80004cec <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ce4:	2985                	addiw	s3,s3,1
    80004ce6:	0905                	addi	s2,s2,1
    80004ce8:	fd3a91e3          	bne	s5,s3,80004caa <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cec:	21c48513          	addi	a0,s1,540
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	598080e7          	jalr	1432(ra) # 80002288 <wakeup>
  release(&pi->lock);
    80004cf8:	8526                	mv	a0,s1
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	fa4080e7          	jalr	-92(ra) # 80000c9e <release>
  return i;
}
    80004d02:	854e                	mv	a0,s3
    80004d04:	60a6                	ld	ra,72(sp)
    80004d06:	6406                	ld	s0,64(sp)
    80004d08:	74e2                	ld	s1,56(sp)
    80004d0a:	7942                	ld	s2,48(sp)
    80004d0c:	79a2                	ld	s3,40(sp)
    80004d0e:	7a02                	ld	s4,32(sp)
    80004d10:	6ae2                	ld	s5,24(sp)
    80004d12:	6b42                	ld	s6,16(sp)
    80004d14:	6161                	addi	sp,sp,80
    80004d16:	8082                	ret
      release(&pi->lock);
    80004d18:	8526                	mv	a0,s1
    80004d1a:	ffffc097          	auipc	ra,0xffffc
    80004d1e:	f84080e7          	jalr	-124(ra) # 80000c9e <release>
      return -1;
    80004d22:	59fd                	li	s3,-1
    80004d24:	bff9                	j	80004d02 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d26:	4981                	li	s3,0
    80004d28:	b7d1                	j	80004cec <piperead+0xb4>

0000000080004d2a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d2a:	1141                	addi	sp,sp,-16
    80004d2c:	e422                	sd	s0,8(sp)
    80004d2e:	0800                	addi	s0,sp,16
    80004d30:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d32:	8905                	andi	a0,a0,1
    80004d34:	c111                	beqz	a0,80004d38 <flags2perm+0xe>
      perm = PTE_X;
    80004d36:	4521                	li	a0,8
    if(flags & 0x2)
    80004d38:	8b89                	andi	a5,a5,2
    80004d3a:	c399                	beqz	a5,80004d40 <flags2perm+0x16>
      perm |= PTE_W;
    80004d3c:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d40:	6422                	ld	s0,8(sp)
    80004d42:	0141                	addi	sp,sp,16
    80004d44:	8082                	ret

0000000080004d46 <exec>:

int
exec(char *path, char **argv)
{
    80004d46:	df010113          	addi	sp,sp,-528
    80004d4a:	20113423          	sd	ra,520(sp)
    80004d4e:	20813023          	sd	s0,512(sp)
    80004d52:	ffa6                	sd	s1,504(sp)
    80004d54:	fbca                	sd	s2,496(sp)
    80004d56:	f7ce                	sd	s3,488(sp)
    80004d58:	f3d2                	sd	s4,480(sp)
    80004d5a:	efd6                	sd	s5,472(sp)
    80004d5c:	ebda                	sd	s6,464(sp)
    80004d5e:	e7de                	sd	s7,456(sp)
    80004d60:	e3e2                	sd	s8,448(sp)
    80004d62:	ff66                	sd	s9,440(sp)
    80004d64:	fb6a                	sd	s10,432(sp)
    80004d66:	f76e                	sd	s11,424(sp)
    80004d68:	0c00                	addi	s0,sp,528
    80004d6a:	84aa                	mv	s1,a0
    80004d6c:	dea43c23          	sd	a0,-520(s0)
    80004d70:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	da0080e7          	jalr	-608(ra) # 80001b14 <myproc>
    80004d7c:	892a                	mv	s2,a0

  begin_op();
    80004d7e:	fffff097          	auipc	ra,0xfffff
    80004d82:	474080e7          	jalr	1140(ra) # 800041f2 <begin_op>

  if((ip = namei(path)) == 0){
    80004d86:	8526                	mv	a0,s1
    80004d88:	fffff097          	auipc	ra,0xfffff
    80004d8c:	24e080e7          	jalr	590(ra) # 80003fd6 <namei>
    80004d90:	c92d                	beqz	a0,80004e02 <exec+0xbc>
    80004d92:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	a9c080e7          	jalr	-1380(ra) # 80003830 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d9c:	04000713          	li	a4,64
    80004da0:	4681                	li	a3,0
    80004da2:	e5040613          	addi	a2,s0,-432
    80004da6:	4581                	li	a1,0
    80004da8:	8526                	mv	a0,s1
    80004daa:	fffff097          	auipc	ra,0xfffff
    80004dae:	d3a080e7          	jalr	-710(ra) # 80003ae4 <readi>
    80004db2:	04000793          	li	a5,64
    80004db6:	00f51a63          	bne	a0,a5,80004dca <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004dba:	e5042703          	lw	a4,-432(s0)
    80004dbe:	464c47b7          	lui	a5,0x464c4
    80004dc2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dc6:	04f70463          	beq	a4,a5,80004e0e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004dca:	8526                	mv	a0,s1
    80004dcc:	fffff097          	auipc	ra,0xfffff
    80004dd0:	cc6080e7          	jalr	-826(ra) # 80003a92 <iunlockput>
    end_op();
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	49e080e7          	jalr	1182(ra) # 80004272 <end_op>
  }
  return -1;
    80004ddc:	557d                	li	a0,-1
}
    80004dde:	20813083          	ld	ra,520(sp)
    80004de2:	20013403          	ld	s0,512(sp)
    80004de6:	74fe                	ld	s1,504(sp)
    80004de8:	795e                	ld	s2,496(sp)
    80004dea:	79be                	ld	s3,488(sp)
    80004dec:	7a1e                	ld	s4,480(sp)
    80004dee:	6afe                	ld	s5,472(sp)
    80004df0:	6b5e                	ld	s6,464(sp)
    80004df2:	6bbe                	ld	s7,456(sp)
    80004df4:	6c1e                	ld	s8,448(sp)
    80004df6:	7cfa                	ld	s9,440(sp)
    80004df8:	7d5a                	ld	s10,432(sp)
    80004dfa:	7dba                	ld	s11,424(sp)
    80004dfc:	21010113          	addi	sp,sp,528
    80004e00:	8082                	ret
    end_op();
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	470080e7          	jalr	1136(ra) # 80004272 <end_op>
    return -1;
    80004e0a:	557d                	li	a0,-1
    80004e0c:	bfc9                	j	80004dde <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e0e:	854a                	mv	a0,s2
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	dc8080e7          	jalr	-568(ra) # 80001bd8 <proc_pagetable>
    80004e18:	8baa                	mv	s7,a0
    80004e1a:	d945                	beqz	a0,80004dca <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e1c:	e7042983          	lw	s3,-400(s0)
    80004e20:	e8845783          	lhu	a5,-376(s0)
    80004e24:	c7ad                	beqz	a5,80004e8e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e26:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e28:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e2a:	6c85                	lui	s9,0x1
    80004e2c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e30:	def43823          	sd	a5,-528(s0)
    80004e34:	ac3d                	j	80005072 <exec+0x32c>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e36:	00004517          	auipc	a0,0x4
    80004e3a:	85250513          	addi	a0,a0,-1966 # 80008688 <syscalls+0x280>
    80004e3e:	ffffb097          	auipc	ra,0xffffb
    80004e42:	706080e7          	jalr	1798(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e46:	8756                	mv	a4,s5
    80004e48:	012d86bb          	addw	a3,s11,s2
    80004e4c:	4581                	li	a1,0
    80004e4e:	8526                	mv	a0,s1
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	c94080e7          	jalr	-876(ra) # 80003ae4 <readi>
    80004e58:	2501                	sext.w	a0,a0
    80004e5a:	1caa9063          	bne	s5,a0,8000501a <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004e5e:	6785                	lui	a5,0x1
    80004e60:	0127893b          	addw	s2,a5,s2
    80004e64:	77fd                	lui	a5,0xfffff
    80004e66:	01478a3b          	addw	s4,a5,s4
    80004e6a:	1f897b63          	bgeu	s2,s8,80005060 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004e6e:	02091593          	slli	a1,s2,0x20
    80004e72:	9181                	srli	a1,a1,0x20
    80004e74:	95ea                	add	a1,a1,s10
    80004e76:	855e                	mv	a0,s7
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	90a080e7          	jalr	-1782(ra) # 80001782 <walkaddr>
    80004e80:	862a                	mv	a2,a0
    if(pa == 0)
    80004e82:	d955                	beqz	a0,80004e36 <exec+0xf0>
      n = PGSIZE;
    80004e84:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e86:	fd9a70e3          	bgeu	s4,s9,80004e46 <exec+0x100>
      n = sz - i;
    80004e8a:	8ad2                	mv	s5,s4
    80004e8c:	bf6d                	j	80004e46 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e8e:	4a01                	li	s4,0
  iunlockput(ip);
    80004e90:	8526                	mv	a0,s1
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	c00080e7          	jalr	-1024(ra) # 80003a92 <iunlockput>
  end_op();
    80004e9a:	fffff097          	auipc	ra,0xfffff
    80004e9e:	3d8080e7          	jalr	984(ra) # 80004272 <end_op>
  p = myproc();
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	c72080e7          	jalr	-910(ra) # 80001b14 <myproc>
    80004eaa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eac:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004eb0:	6785                	lui	a5,0x1
    80004eb2:	17fd                	addi	a5,a5,-1
    80004eb4:	9a3e                	add	s4,s4,a5
    80004eb6:	757d                	lui	a0,0xfffff
    80004eb8:	00aa77b3          	and	a5,s4,a0
    80004ebc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ec0:	4691                	li	a3,4
    80004ec2:	6609                	lui	a2,0x2
    80004ec4:	963e                	add	a2,a2,a5
    80004ec6:	85be                	mv	a1,a5
    80004ec8:	855e                	mv	a0,s7
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	5ae080e7          	jalr	1454(ra) # 80001478 <uvmalloc>
    80004ed2:	8b2a                	mv	s6,a0
  ip = 0;
    80004ed4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ed6:	14050263          	beqz	a0,8000501a <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eda:	75f9                	lui	a1,0xffffe
    80004edc:	95aa                	add	a1,a1,a0
    80004ede:	855e                	mv	a0,s7
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	7a2080e7          	jalr	1954(ra) # 80001682 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ee8:	7c7d                	lui	s8,0xfffff
    80004eea:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eec:	e0043783          	ld	a5,-512(s0)
    80004ef0:	6388                	ld	a0,0(a5)
    80004ef2:	c535                	beqz	a0,80004f5e <exec+0x218>
    80004ef4:	e9040993          	addi	s3,s0,-368
    80004ef8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004efc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	f6c080e7          	jalr	-148(ra) # 80000e6a <strlen>
    80004f06:	2505                	addiw	a0,a0,1
    80004f08:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f0c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f10:	13896c63          	bltu	s2,s8,80005048 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f14:	e0043d83          	ld	s11,-512(s0)
    80004f18:	000dba03          	ld	s4,0(s11)
    80004f1c:	8552                	mv	a0,s4
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	f4c080e7          	jalr	-180(ra) # 80000e6a <strlen>
    80004f26:	0015069b          	addiw	a3,a0,1
    80004f2a:	8652                	mv	a2,s4
    80004f2c:	85ca                	mv	a1,s2
    80004f2e:	855e                	mv	a0,s7
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	8a2080e7          	jalr	-1886(ra) # 800017d2 <copyout>
    80004f38:	10054c63          	bltz	a0,80005050 <exec+0x30a>
    ustack[argc] = sp;
    80004f3c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f40:	0485                	addi	s1,s1,1
    80004f42:	008d8793          	addi	a5,s11,8
    80004f46:	e0f43023          	sd	a5,-512(s0)
    80004f4a:	008db503          	ld	a0,8(s11)
    80004f4e:	c911                	beqz	a0,80004f62 <exec+0x21c>
    if(argc >= MAXARG)
    80004f50:	09a1                	addi	s3,s3,8
    80004f52:	fb3c96e3          	bne	s9,s3,80004efe <exec+0x1b8>
  sz = sz1;
    80004f56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f5a:	4481                	li	s1,0
    80004f5c:	a87d                	j	8000501a <exec+0x2d4>
  sp = sz;
    80004f5e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f60:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f62:	00349793          	slli	a5,s1,0x3
    80004f66:	f9040713          	addi	a4,s0,-112
    80004f6a:	97ba                	add	a5,a5,a4
    80004f6c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004f70:	00148693          	addi	a3,s1,1
    80004f74:	068e                	slli	a3,a3,0x3
    80004f76:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f7a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f7e:	01897663          	bgeu	s2,s8,80004f8a <exec+0x244>
  sz = sz1;
    80004f82:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f86:	4481                	li	s1,0
    80004f88:	a849                	j	8000501a <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f8a:	e9040613          	addi	a2,s0,-368
    80004f8e:	85ca                	mv	a1,s2
    80004f90:	855e                	mv	a0,s7
    80004f92:	ffffd097          	auipc	ra,0xffffd
    80004f96:	840080e7          	jalr	-1984(ra) # 800017d2 <copyout>
    80004f9a:	0a054f63          	bltz	a0,80005058 <exec+0x312>
  p->trapframe->a1 = sp;
    80004f9e:	058ab783          	ld	a5,88(s5)
    80004fa2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fa6:	df843783          	ld	a5,-520(s0)
    80004faa:	0007c703          	lbu	a4,0(a5)
    80004fae:	cf11                	beqz	a4,80004fca <exec+0x284>
    80004fb0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fb2:	02f00693          	li	a3,47
    80004fb6:	a039                	j	80004fc4 <exec+0x27e>
      last = s+1;
    80004fb8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004fbc:	0785                	addi	a5,a5,1
    80004fbe:	fff7c703          	lbu	a4,-1(a5)
    80004fc2:	c701                	beqz	a4,80004fca <exec+0x284>
    if(*s == '/')
    80004fc4:	fed71ce3          	bne	a4,a3,80004fbc <exec+0x276>
    80004fc8:	bfc5                	j	80004fb8 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fca:	4641                	li	a2,16
    80004fcc:	df843583          	ld	a1,-520(s0)
    80004fd0:	158a8513          	addi	a0,s5,344
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	e64080e7          	jalr	-412(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fdc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fe0:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fe4:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fe8:	058ab783          	ld	a5,88(s5)
    80004fec:	e6843703          	ld	a4,-408(s0)
    80004ff0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004ff2:	058ab783          	ld	a5,88(s5)
    80004ff6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ffa:	85ea                	mv	a1,s10
    80004ffc:	ffffd097          	auipc	ra,0xffffd
    80005000:	c78080e7          	jalr	-904(ra) # 80001c74 <proc_freepagetable>
  vmprint(p->pagetable);
    80005004:	050ab503          	ld	a0,80(s5)
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	6ac080e7          	jalr	1708(ra) # 800016b4 <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005010:	0004851b          	sext.w	a0,s1
    80005014:	b3e9                	j	80004dde <exec+0x98>
    80005016:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000501a:	e0843583          	ld	a1,-504(s0)
    8000501e:	855e                	mv	a0,s7
    80005020:	ffffd097          	auipc	ra,0xffffd
    80005024:	c54080e7          	jalr	-940(ra) # 80001c74 <proc_freepagetable>
  if(ip){
    80005028:	da0491e3          	bnez	s1,80004dca <exec+0x84>
  return -1;
    8000502c:	557d                	li	a0,-1
    8000502e:	bb45                	j	80004dde <exec+0x98>
    80005030:	e1443423          	sd	s4,-504(s0)
    80005034:	b7dd                	j	8000501a <exec+0x2d4>
    80005036:	e1443423          	sd	s4,-504(s0)
    8000503a:	b7c5                	j	8000501a <exec+0x2d4>
    8000503c:	e1443423          	sd	s4,-504(s0)
    80005040:	bfe9                	j	8000501a <exec+0x2d4>
    80005042:	e1443423          	sd	s4,-504(s0)
    80005046:	bfd1                	j	8000501a <exec+0x2d4>
  sz = sz1;
    80005048:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000504c:	4481                	li	s1,0
    8000504e:	b7f1                	j	8000501a <exec+0x2d4>
  sz = sz1;
    80005050:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005054:	4481                	li	s1,0
    80005056:	b7d1                	j	8000501a <exec+0x2d4>
  sz = sz1;
    80005058:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000505c:	4481                	li	s1,0
    8000505e:	bf75                	j	8000501a <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005060:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005064:	2b05                	addiw	s6,s6,1
    80005066:	0389899b          	addiw	s3,s3,56
    8000506a:	e8845783          	lhu	a5,-376(s0)
    8000506e:	e2fb51e3          	bge	s6,a5,80004e90 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005072:	2981                	sext.w	s3,s3
    80005074:	03800713          	li	a4,56
    80005078:	86ce                	mv	a3,s3
    8000507a:	e1840613          	addi	a2,s0,-488
    8000507e:	4581                	li	a1,0
    80005080:	8526                	mv	a0,s1
    80005082:	fffff097          	auipc	ra,0xfffff
    80005086:	a62080e7          	jalr	-1438(ra) # 80003ae4 <readi>
    8000508a:	03800793          	li	a5,56
    8000508e:	f8f514e3          	bne	a0,a5,80005016 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005092:	e1842783          	lw	a5,-488(s0)
    80005096:	4705                	li	a4,1
    80005098:	fce796e3          	bne	a5,a4,80005064 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000509c:	e4043903          	ld	s2,-448(s0)
    800050a0:	e3843783          	ld	a5,-456(s0)
    800050a4:	f8f966e3          	bltu	s2,a5,80005030 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050a8:	e2843783          	ld	a5,-472(s0)
    800050ac:	993e                	add	s2,s2,a5
    800050ae:	f8f964e3          	bltu	s2,a5,80005036 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800050b2:	df043703          	ld	a4,-528(s0)
    800050b6:	8ff9                	and	a5,a5,a4
    800050b8:	f3d1                	bnez	a5,8000503c <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050ba:	e1c42503          	lw	a0,-484(s0)
    800050be:	00000097          	auipc	ra,0x0
    800050c2:	c6c080e7          	jalr	-916(ra) # 80004d2a <flags2perm>
    800050c6:	86aa                	mv	a3,a0
    800050c8:	864a                	mv	a2,s2
    800050ca:	85d2                	mv	a1,s4
    800050cc:	855e                	mv	a0,s7
    800050ce:	ffffc097          	auipc	ra,0xffffc
    800050d2:	3aa080e7          	jalr	938(ra) # 80001478 <uvmalloc>
    800050d6:	e0a43423          	sd	a0,-504(s0)
    800050da:	d525                	beqz	a0,80005042 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050dc:	e2843d03          	ld	s10,-472(s0)
    800050e0:	e2042d83          	lw	s11,-480(s0)
    800050e4:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050e8:	f60c0ce3          	beqz	s8,80005060 <exec+0x31a>
    800050ec:	8a62                	mv	s4,s8
    800050ee:	4901                	li	s2,0
    800050f0:	bbbd                	j	80004e6e <exec+0x128>

00000000800050f2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050f2:	7179                	addi	sp,sp,-48
    800050f4:	f406                	sd	ra,40(sp)
    800050f6:	f022                	sd	s0,32(sp)
    800050f8:	ec26                	sd	s1,24(sp)
    800050fa:	e84a                	sd	s2,16(sp)
    800050fc:	1800                	addi	s0,sp,48
    800050fe:	892e                	mv	s2,a1
    80005100:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005102:	fdc40593          	addi	a1,s0,-36
    80005106:	ffffe097          	auipc	ra,0xffffe
    8000510a:	bba080e7          	jalr	-1094(ra) # 80002cc0 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000510e:	fdc42703          	lw	a4,-36(s0)
    80005112:	47bd                	li	a5,15
    80005114:	02e7eb63          	bltu	a5,a4,8000514a <argfd+0x58>
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	9fc080e7          	jalr	-1540(ra) # 80001b14 <myproc>
    80005120:	fdc42703          	lw	a4,-36(s0)
    80005124:	01a70793          	addi	a5,a4,26
    80005128:	078e                	slli	a5,a5,0x3
    8000512a:	953e                	add	a0,a0,a5
    8000512c:	611c                	ld	a5,0(a0)
    8000512e:	c385                	beqz	a5,8000514e <argfd+0x5c>
    return -1;
  if(pfd)
    80005130:	00090463          	beqz	s2,80005138 <argfd+0x46>
    *pfd = fd;
    80005134:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005138:	4501                	li	a0,0
  if(pf)
    8000513a:	c091                	beqz	s1,8000513e <argfd+0x4c>
    *pf = f;
    8000513c:	e09c                	sd	a5,0(s1)
}
    8000513e:	70a2                	ld	ra,40(sp)
    80005140:	7402                	ld	s0,32(sp)
    80005142:	64e2                	ld	s1,24(sp)
    80005144:	6942                	ld	s2,16(sp)
    80005146:	6145                	addi	sp,sp,48
    80005148:	8082                	ret
    return -1;
    8000514a:	557d                	li	a0,-1
    8000514c:	bfcd                	j	8000513e <argfd+0x4c>
    8000514e:	557d                	li	a0,-1
    80005150:	b7fd                	j	8000513e <argfd+0x4c>

0000000080005152 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005152:	1101                	addi	sp,sp,-32
    80005154:	ec06                	sd	ra,24(sp)
    80005156:	e822                	sd	s0,16(sp)
    80005158:	e426                	sd	s1,8(sp)
    8000515a:	1000                	addi	s0,sp,32
    8000515c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000515e:	ffffd097          	auipc	ra,0xffffd
    80005162:	9b6080e7          	jalr	-1610(ra) # 80001b14 <myproc>
    80005166:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005168:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd3b0>
    8000516c:	4501                	li	a0,0
    8000516e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005170:	6398                	ld	a4,0(a5)
    80005172:	cb19                	beqz	a4,80005188 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005174:	2505                	addiw	a0,a0,1
    80005176:	07a1                	addi	a5,a5,8
    80005178:	fed51ce3          	bne	a0,a3,80005170 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000517c:	557d                	li	a0,-1
}
    8000517e:	60e2                	ld	ra,24(sp)
    80005180:	6442                	ld	s0,16(sp)
    80005182:	64a2                	ld	s1,8(sp)
    80005184:	6105                	addi	sp,sp,32
    80005186:	8082                	ret
      p->ofile[fd] = f;
    80005188:	01a50793          	addi	a5,a0,26
    8000518c:	078e                	slli	a5,a5,0x3
    8000518e:	963e                	add	a2,a2,a5
    80005190:	e204                	sd	s1,0(a2)
      return fd;
    80005192:	b7f5                	j	8000517e <fdalloc+0x2c>

0000000080005194 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005194:	715d                	addi	sp,sp,-80
    80005196:	e486                	sd	ra,72(sp)
    80005198:	e0a2                	sd	s0,64(sp)
    8000519a:	fc26                	sd	s1,56(sp)
    8000519c:	f84a                	sd	s2,48(sp)
    8000519e:	f44e                	sd	s3,40(sp)
    800051a0:	f052                	sd	s4,32(sp)
    800051a2:	ec56                	sd	s5,24(sp)
    800051a4:	e85a                	sd	s6,16(sp)
    800051a6:	0880                	addi	s0,sp,80
    800051a8:	8b2e                	mv	s6,a1
    800051aa:	89b2                	mv	s3,a2
    800051ac:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051ae:	fb040593          	addi	a1,s0,-80
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	e42080e7          	jalr	-446(ra) # 80003ff4 <nameiparent>
    800051ba:	84aa                	mv	s1,a0
    800051bc:	16050063          	beqz	a0,8000531c <create+0x188>
    return 0;

  ilock(dp);
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	670080e7          	jalr	1648(ra) # 80003830 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051c8:	4601                	li	a2,0
    800051ca:	fb040593          	addi	a1,s0,-80
    800051ce:	8526                	mv	a0,s1
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	b44080e7          	jalr	-1212(ra) # 80003d14 <dirlookup>
    800051d8:	8aaa                	mv	s5,a0
    800051da:	c931                	beqz	a0,8000522e <create+0x9a>
    iunlockput(dp);
    800051dc:	8526                	mv	a0,s1
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	8b4080e7          	jalr	-1868(ra) # 80003a92 <iunlockput>
    ilock(ip);
    800051e6:	8556                	mv	a0,s5
    800051e8:	ffffe097          	auipc	ra,0xffffe
    800051ec:	648080e7          	jalr	1608(ra) # 80003830 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051f0:	000b059b          	sext.w	a1,s6
    800051f4:	4789                	li	a5,2
    800051f6:	02f59563          	bne	a1,a5,80005220 <create+0x8c>
    800051fa:	044ad783          	lhu	a5,68(s5)
    800051fe:	37f9                	addiw	a5,a5,-2
    80005200:	17c2                	slli	a5,a5,0x30
    80005202:	93c1                	srli	a5,a5,0x30
    80005204:	4705                	li	a4,1
    80005206:	00f76d63          	bltu	a4,a5,80005220 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000520a:	8556                	mv	a0,s5
    8000520c:	60a6                	ld	ra,72(sp)
    8000520e:	6406                	ld	s0,64(sp)
    80005210:	74e2                	ld	s1,56(sp)
    80005212:	7942                	ld	s2,48(sp)
    80005214:	79a2                	ld	s3,40(sp)
    80005216:	7a02                	ld	s4,32(sp)
    80005218:	6ae2                	ld	s5,24(sp)
    8000521a:	6b42                	ld	s6,16(sp)
    8000521c:	6161                	addi	sp,sp,80
    8000521e:	8082                	ret
    iunlockput(ip);
    80005220:	8556                	mv	a0,s5
    80005222:	fffff097          	auipc	ra,0xfffff
    80005226:	870080e7          	jalr	-1936(ra) # 80003a92 <iunlockput>
    return 0;
    8000522a:	4a81                	li	s5,0
    8000522c:	bff9                	j	8000520a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000522e:	85da                	mv	a1,s6
    80005230:	4088                	lw	a0,0(s1)
    80005232:	ffffe097          	auipc	ra,0xffffe
    80005236:	462080e7          	jalr	1122(ra) # 80003694 <ialloc>
    8000523a:	8a2a                	mv	s4,a0
    8000523c:	c921                	beqz	a0,8000528c <create+0xf8>
  ilock(ip);
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	5f2080e7          	jalr	1522(ra) # 80003830 <ilock>
  ip->major = major;
    80005246:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000524a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000524e:	4785                	li	a5,1
    80005250:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005254:	8552                	mv	a0,s4
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	510080e7          	jalr	1296(ra) # 80003766 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000525e:	000b059b          	sext.w	a1,s6
    80005262:	4785                	li	a5,1
    80005264:	02f58b63          	beq	a1,a5,8000529a <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005268:	004a2603          	lw	a2,4(s4)
    8000526c:	fb040593          	addi	a1,s0,-80
    80005270:	8526                	mv	a0,s1
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	cb2080e7          	jalr	-846(ra) # 80003f24 <dirlink>
    8000527a:	06054f63          	bltz	a0,800052f8 <create+0x164>
  iunlockput(dp);
    8000527e:	8526                	mv	a0,s1
    80005280:	fffff097          	auipc	ra,0xfffff
    80005284:	812080e7          	jalr	-2030(ra) # 80003a92 <iunlockput>
  return ip;
    80005288:	8ad2                	mv	s5,s4
    8000528a:	b741                	j	8000520a <create+0x76>
    iunlockput(dp);
    8000528c:	8526                	mv	a0,s1
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	804080e7          	jalr	-2044(ra) # 80003a92 <iunlockput>
    return 0;
    80005296:	8ad2                	mv	s5,s4
    80005298:	bf8d                	j	8000520a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000529a:	004a2603          	lw	a2,4(s4)
    8000529e:	00003597          	auipc	a1,0x3
    800052a2:	40a58593          	addi	a1,a1,1034 # 800086a8 <syscalls+0x2a0>
    800052a6:	8552                	mv	a0,s4
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	c7c080e7          	jalr	-900(ra) # 80003f24 <dirlink>
    800052b0:	04054463          	bltz	a0,800052f8 <create+0x164>
    800052b4:	40d0                	lw	a2,4(s1)
    800052b6:	00003597          	auipc	a1,0x3
    800052ba:	3fa58593          	addi	a1,a1,1018 # 800086b0 <syscalls+0x2a8>
    800052be:	8552                	mv	a0,s4
    800052c0:	fffff097          	auipc	ra,0xfffff
    800052c4:	c64080e7          	jalr	-924(ra) # 80003f24 <dirlink>
    800052c8:	02054863          	bltz	a0,800052f8 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800052cc:	004a2603          	lw	a2,4(s4)
    800052d0:	fb040593          	addi	a1,s0,-80
    800052d4:	8526                	mv	a0,s1
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	c4e080e7          	jalr	-946(ra) # 80003f24 <dirlink>
    800052de:	00054d63          	bltz	a0,800052f8 <create+0x164>
    dp->nlink++;  // for ".."
    800052e2:	04a4d783          	lhu	a5,74(s1)
    800052e6:	2785                	addiw	a5,a5,1
    800052e8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800052ec:	8526                	mv	a0,s1
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	478080e7          	jalr	1144(ra) # 80003766 <iupdate>
    800052f6:	b761                	j	8000527e <create+0xea>
  ip->nlink = 0;
    800052f8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800052fc:	8552                	mv	a0,s4
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	468080e7          	jalr	1128(ra) # 80003766 <iupdate>
  iunlockput(ip);
    80005306:	8552                	mv	a0,s4
    80005308:	ffffe097          	auipc	ra,0xffffe
    8000530c:	78a080e7          	jalr	1930(ra) # 80003a92 <iunlockput>
  iunlockput(dp);
    80005310:	8526                	mv	a0,s1
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	780080e7          	jalr	1920(ra) # 80003a92 <iunlockput>
  return 0;
    8000531a:	bdc5                	j	8000520a <create+0x76>
    return 0;
    8000531c:	8aaa                	mv	s5,a0
    8000531e:	b5f5                	j	8000520a <create+0x76>

0000000080005320 <sys_dup>:
{
    80005320:	7179                	addi	sp,sp,-48
    80005322:	f406                	sd	ra,40(sp)
    80005324:	f022                	sd	s0,32(sp)
    80005326:	ec26                	sd	s1,24(sp)
    80005328:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000532a:	fd840613          	addi	a2,s0,-40
    8000532e:	4581                	li	a1,0
    80005330:	4501                	li	a0,0
    80005332:	00000097          	auipc	ra,0x0
    80005336:	dc0080e7          	jalr	-576(ra) # 800050f2 <argfd>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000533c:	02054363          	bltz	a0,80005362 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005340:	fd843503          	ld	a0,-40(s0)
    80005344:	00000097          	auipc	ra,0x0
    80005348:	e0e080e7          	jalr	-498(ra) # 80005152 <fdalloc>
    8000534c:	84aa                	mv	s1,a0
    return -1;
    8000534e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005350:	00054963          	bltz	a0,80005362 <sys_dup+0x42>
  filedup(f);
    80005354:	fd843503          	ld	a0,-40(s0)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	314080e7          	jalr	788(ra) # 8000466c <filedup>
  return fd;
    80005360:	87a6                	mv	a5,s1
}
    80005362:	853e                	mv	a0,a5
    80005364:	70a2                	ld	ra,40(sp)
    80005366:	7402                	ld	s0,32(sp)
    80005368:	64e2                	ld	s1,24(sp)
    8000536a:	6145                	addi	sp,sp,48
    8000536c:	8082                	ret

000000008000536e <sys_read>:
{
    8000536e:	7179                	addi	sp,sp,-48
    80005370:	f406                	sd	ra,40(sp)
    80005372:	f022                	sd	s0,32(sp)
    80005374:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005376:	fd840593          	addi	a1,s0,-40
    8000537a:	4505                	li	a0,1
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	964080e7          	jalr	-1692(ra) # 80002ce0 <argaddr>
  argint(2, &n);
    80005384:	fe440593          	addi	a1,s0,-28
    80005388:	4509                	li	a0,2
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	936080e7          	jalr	-1738(ra) # 80002cc0 <argint>
  if(argfd(0, 0, &f) < 0)
    80005392:	fe840613          	addi	a2,s0,-24
    80005396:	4581                	li	a1,0
    80005398:	4501                	li	a0,0
    8000539a:	00000097          	auipc	ra,0x0
    8000539e:	d58080e7          	jalr	-680(ra) # 800050f2 <argfd>
    800053a2:	87aa                	mv	a5,a0
    return -1;
    800053a4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053a6:	0007cc63          	bltz	a5,800053be <sys_read+0x50>
  return fileread(f, p, n);
    800053aa:	fe442603          	lw	a2,-28(s0)
    800053ae:	fd843583          	ld	a1,-40(s0)
    800053b2:	fe843503          	ld	a0,-24(s0)
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	442080e7          	jalr	1090(ra) # 800047f8 <fileread>
}
    800053be:	70a2                	ld	ra,40(sp)
    800053c0:	7402                	ld	s0,32(sp)
    800053c2:	6145                	addi	sp,sp,48
    800053c4:	8082                	ret

00000000800053c6 <sys_write>:
{
    800053c6:	7179                	addi	sp,sp,-48
    800053c8:	f406                	sd	ra,40(sp)
    800053ca:	f022                	sd	s0,32(sp)
    800053cc:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053ce:	fd840593          	addi	a1,s0,-40
    800053d2:	4505                	li	a0,1
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	90c080e7          	jalr	-1780(ra) # 80002ce0 <argaddr>
  argint(2, &n);
    800053dc:	fe440593          	addi	a1,s0,-28
    800053e0:	4509                	li	a0,2
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	8de080e7          	jalr	-1826(ra) # 80002cc0 <argint>
  if(argfd(0, 0, &f) < 0)
    800053ea:	fe840613          	addi	a2,s0,-24
    800053ee:	4581                	li	a1,0
    800053f0:	4501                	li	a0,0
    800053f2:	00000097          	auipc	ra,0x0
    800053f6:	d00080e7          	jalr	-768(ra) # 800050f2 <argfd>
    800053fa:	87aa                	mv	a5,a0
    return -1;
    800053fc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053fe:	0007cc63          	bltz	a5,80005416 <sys_write+0x50>
  return filewrite(f, p, n);
    80005402:	fe442603          	lw	a2,-28(s0)
    80005406:	fd843583          	ld	a1,-40(s0)
    8000540a:	fe843503          	ld	a0,-24(s0)
    8000540e:	fffff097          	auipc	ra,0xfffff
    80005412:	4ac080e7          	jalr	1196(ra) # 800048ba <filewrite>
}
    80005416:	70a2                	ld	ra,40(sp)
    80005418:	7402                	ld	s0,32(sp)
    8000541a:	6145                	addi	sp,sp,48
    8000541c:	8082                	ret

000000008000541e <sys_close>:
{
    8000541e:	1101                	addi	sp,sp,-32
    80005420:	ec06                	sd	ra,24(sp)
    80005422:	e822                	sd	s0,16(sp)
    80005424:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005426:	fe040613          	addi	a2,s0,-32
    8000542a:	fec40593          	addi	a1,s0,-20
    8000542e:	4501                	li	a0,0
    80005430:	00000097          	auipc	ra,0x0
    80005434:	cc2080e7          	jalr	-830(ra) # 800050f2 <argfd>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000543a:	02054463          	bltz	a0,80005462 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000543e:	ffffc097          	auipc	ra,0xffffc
    80005442:	6d6080e7          	jalr	1750(ra) # 80001b14 <myproc>
    80005446:	fec42783          	lw	a5,-20(s0)
    8000544a:	07e9                	addi	a5,a5,26
    8000544c:	078e                	slli	a5,a5,0x3
    8000544e:	97aa                	add	a5,a5,a0
    80005450:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005454:	fe043503          	ld	a0,-32(s0)
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	266080e7          	jalr	614(ra) # 800046be <fileclose>
  return 0;
    80005460:	4781                	li	a5,0
}
    80005462:	853e                	mv	a0,a5
    80005464:	60e2                	ld	ra,24(sp)
    80005466:	6442                	ld	s0,16(sp)
    80005468:	6105                	addi	sp,sp,32
    8000546a:	8082                	ret

000000008000546c <sys_fstat>:
{
    8000546c:	1101                	addi	sp,sp,-32
    8000546e:	ec06                	sd	ra,24(sp)
    80005470:	e822                	sd	s0,16(sp)
    80005472:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005474:	fe040593          	addi	a1,s0,-32
    80005478:	4505                	li	a0,1
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	866080e7          	jalr	-1946(ra) # 80002ce0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005482:	fe840613          	addi	a2,s0,-24
    80005486:	4581                	li	a1,0
    80005488:	4501                	li	a0,0
    8000548a:	00000097          	auipc	ra,0x0
    8000548e:	c68080e7          	jalr	-920(ra) # 800050f2 <argfd>
    80005492:	87aa                	mv	a5,a0
    return -1;
    80005494:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005496:	0007ca63          	bltz	a5,800054aa <sys_fstat+0x3e>
  return filestat(f, st);
    8000549a:	fe043583          	ld	a1,-32(s0)
    8000549e:	fe843503          	ld	a0,-24(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	2e4080e7          	jalr	740(ra) # 80004786 <filestat>
}
    800054aa:	60e2                	ld	ra,24(sp)
    800054ac:	6442                	ld	s0,16(sp)
    800054ae:	6105                	addi	sp,sp,32
    800054b0:	8082                	ret

00000000800054b2 <sys_link>:
{
    800054b2:	7169                	addi	sp,sp,-304
    800054b4:	f606                	sd	ra,296(sp)
    800054b6:	f222                	sd	s0,288(sp)
    800054b8:	ee26                	sd	s1,280(sp)
    800054ba:	ea4a                	sd	s2,272(sp)
    800054bc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054be:	08000613          	li	a2,128
    800054c2:	ed040593          	addi	a1,s0,-304
    800054c6:	4501                	li	a0,0
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	838080e7          	jalr	-1992(ra) # 80002d00 <argstr>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d2:	10054e63          	bltz	a0,800055ee <sys_link+0x13c>
    800054d6:	08000613          	li	a2,128
    800054da:	f5040593          	addi	a1,s0,-176
    800054de:	4505                	li	a0,1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	820080e7          	jalr	-2016(ra) # 80002d00 <argstr>
    return -1;
    800054e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ea:	10054263          	bltz	a0,800055ee <sys_link+0x13c>
  begin_op();
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	d04080e7          	jalr	-764(ra) # 800041f2 <begin_op>
  if((ip = namei(old)) == 0){
    800054f6:	ed040513          	addi	a0,s0,-304
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	adc080e7          	jalr	-1316(ra) # 80003fd6 <namei>
    80005502:	84aa                	mv	s1,a0
    80005504:	c551                	beqz	a0,80005590 <sys_link+0xde>
  ilock(ip);
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	32a080e7          	jalr	810(ra) # 80003830 <ilock>
  if(ip->type == T_DIR){
    8000550e:	04449703          	lh	a4,68(s1)
    80005512:	4785                	li	a5,1
    80005514:	08f70463          	beq	a4,a5,8000559c <sys_link+0xea>
  ip->nlink++;
    80005518:	04a4d783          	lhu	a5,74(s1)
    8000551c:	2785                	addiw	a5,a5,1
    8000551e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005522:	8526                	mv	a0,s1
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	242080e7          	jalr	578(ra) # 80003766 <iupdate>
  iunlock(ip);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	3c4080e7          	jalr	964(ra) # 800038f2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005536:	fd040593          	addi	a1,s0,-48
    8000553a:	f5040513          	addi	a0,s0,-176
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	ab6080e7          	jalr	-1354(ra) # 80003ff4 <nameiparent>
    80005546:	892a                	mv	s2,a0
    80005548:	c935                	beqz	a0,800055bc <sys_link+0x10a>
  ilock(dp);
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	2e6080e7          	jalr	742(ra) # 80003830 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005552:	00092703          	lw	a4,0(s2)
    80005556:	409c                	lw	a5,0(s1)
    80005558:	04f71d63          	bne	a4,a5,800055b2 <sys_link+0x100>
    8000555c:	40d0                	lw	a2,4(s1)
    8000555e:	fd040593          	addi	a1,s0,-48
    80005562:	854a                	mv	a0,s2
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	9c0080e7          	jalr	-1600(ra) # 80003f24 <dirlink>
    8000556c:	04054363          	bltz	a0,800055b2 <sys_link+0x100>
  iunlockput(dp);
    80005570:	854a                	mv	a0,s2
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	520080e7          	jalr	1312(ra) # 80003a92 <iunlockput>
  iput(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	46e080e7          	jalr	1134(ra) # 800039ea <iput>
  end_op();
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	cee080e7          	jalr	-786(ra) # 80004272 <end_op>
  return 0;
    8000558c:	4781                	li	a5,0
    8000558e:	a085                	j	800055ee <sys_link+0x13c>
    end_op();
    80005590:	fffff097          	auipc	ra,0xfffff
    80005594:	ce2080e7          	jalr	-798(ra) # 80004272 <end_op>
    return -1;
    80005598:	57fd                	li	a5,-1
    8000559a:	a891                	j	800055ee <sys_link+0x13c>
    iunlockput(ip);
    8000559c:	8526                	mv	a0,s1
    8000559e:	ffffe097          	auipc	ra,0xffffe
    800055a2:	4f4080e7          	jalr	1268(ra) # 80003a92 <iunlockput>
    end_op();
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	ccc080e7          	jalr	-820(ra) # 80004272 <end_op>
    return -1;
    800055ae:	57fd                	li	a5,-1
    800055b0:	a83d                	j	800055ee <sys_link+0x13c>
    iunlockput(dp);
    800055b2:	854a                	mv	a0,s2
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	4de080e7          	jalr	1246(ra) # 80003a92 <iunlockput>
  ilock(ip);
    800055bc:	8526                	mv	a0,s1
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	272080e7          	jalr	626(ra) # 80003830 <ilock>
  ip->nlink--;
    800055c6:	04a4d783          	lhu	a5,74(s1)
    800055ca:	37fd                	addiw	a5,a5,-1
    800055cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055d0:	8526                	mv	a0,s1
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	194080e7          	jalr	404(ra) # 80003766 <iupdate>
  iunlockput(ip);
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	4b6080e7          	jalr	1206(ra) # 80003a92 <iunlockput>
  end_op();
    800055e4:	fffff097          	auipc	ra,0xfffff
    800055e8:	c8e080e7          	jalr	-882(ra) # 80004272 <end_op>
  return -1;
    800055ec:	57fd                	li	a5,-1
}
    800055ee:	853e                	mv	a0,a5
    800055f0:	70b2                	ld	ra,296(sp)
    800055f2:	7412                	ld	s0,288(sp)
    800055f4:	64f2                	ld	s1,280(sp)
    800055f6:	6952                	ld	s2,272(sp)
    800055f8:	6155                	addi	sp,sp,304
    800055fa:	8082                	ret

00000000800055fc <sys_unlink>:
{
    800055fc:	7151                	addi	sp,sp,-240
    800055fe:	f586                	sd	ra,232(sp)
    80005600:	f1a2                	sd	s0,224(sp)
    80005602:	eda6                	sd	s1,216(sp)
    80005604:	e9ca                	sd	s2,208(sp)
    80005606:	e5ce                	sd	s3,200(sp)
    80005608:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000560a:	08000613          	li	a2,128
    8000560e:	f3040593          	addi	a1,s0,-208
    80005612:	4501                	li	a0,0
    80005614:	ffffd097          	auipc	ra,0xffffd
    80005618:	6ec080e7          	jalr	1772(ra) # 80002d00 <argstr>
    8000561c:	18054163          	bltz	a0,8000579e <sys_unlink+0x1a2>
  begin_op();
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	bd2080e7          	jalr	-1070(ra) # 800041f2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005628:	fb040593          	addi	a1,s0,-80
    8000562c:	f3040513          	addi	a0,s0,-208
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	9c4080e7          	jalr	-1596(ra) # 80003ff4 <nameiparent>
    80005638:	84aa                	mv	s1,a0
    8000563a:	c979                	beqz	a0,80005710 <sys_unlink+0x114>
  ilock(dp);
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	1f4080e7          	jalr	500(ra) # 80003830 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005644:	00003597          	auipc	a1,0x3
    80005648:	06458593          	addi	a1,a1,100 # 800086a8 <syscalls+0x2a0>
    8000564c:	fb040513          	addi	a0,s0,-80
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	6aa080e7          	jalr	1706(ra) # 80003cfa <namecmp>
    80005658:	14050a63          	beqz	a0,800057ac <sys_unlink+0x1b0>
    8000565c:	00003597          	auipc	a1,0x3
    80005660:	05458593          	addi	a1,a1,84 # 800086b0 <syscalls+0x2a8>
    80005664:	fb040513          	addi	a0,s0,-80
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	692080e7          	jalr	1682(ra) # 80003cfa <namecmp>
    80005670:	12050e63          	beqz	a0,800057ac <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005674:	f2c40613          	addi	a2,s0,-212
    80005678:	fb040593          	addi	a1,s0,-80
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	696080e7          	jalr	1686(ra) # 80003d14 <dirlookup>
    80005686:	892a                	mv	s2,a0
    80005688:	12050263          	beqz	a0,800057ac <sys_unlink+0x1b0>
  ilock(ip);
    8000568c:	ffffe097          	auipc	ra,0xffffe
    80005690:	1a4080e7          	jalr	420(ra) # 80003830 <ilock>
  if(ip->nlink < 1)
    80005694:	04a91783          	lh	a5,74(s2)
    80005698:	08f05263          	blez	a5,8000571c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000569c:	04491703          	lh	a4,68(s2)
    800056a0:	4785                	li	a5,1
    800056a2:	08f70563          	beq	a4,a5,8000572c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056a6:	4641                	li	a2,16
    800056a8:	4581                	li	a1,0
    800056aa:	fc040513          	addi	a0,s0,-64
    800056ae:	ffffb097          	auipc	ra,0xffffb
    800056b2:	638080e7          	jalr	1592(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056b6:	4741                	li	a4,16
    800056b8:	f2c42683          	lw	a3,-212(s0)
    800056bc:	fc040613          	addi	a2,s0,-64
    800056c0:	4581                	li	a1,0
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	518080e7          	jalr	1304(ra) # 80003bdc <writei>
    800056cc:	47c1                	li	a5,16
    800056ce:	0af51563          	bne	a0,a5,80005778 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056d2:	04491703          	lh	a4,68(s2)
    800056d6:	4785                	li	a5,1
    800056d8:	0af70863          	beq	a4,a5,80005788 <sys_unlink+0x18c>
  iunlockput(dp);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	3b4080e7          	jalr	948(ra) # 80003a92 <iunlockput>
  ip->nlink--;
    800056e6:	04a95783          	lhu	a5,74(s2)
    800056ea:	37fd                	addiw	a5,a5,-1
    800056ec:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056f0:	854a                	mv	a0,s2
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	074080e7          	jalr	116(ra) # 80003766 <iupdate>
  iunlockput(ip);
    800056fa:	854a                	mv	a0,s2
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	396080e7          	jalr	918(ra) # 80003a92 <iunlockput>
  end_op();
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	b6e080e7          	jalr	-1170(ra) # 80004272 <end_op>
  return 0;
    8000570c:	4501                	li	a0,0
    8000570e:	a84d                	j	800057c0 <sys_unlink+0x1c4>
    end_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	b62080e7          	jalr	-1182(ra) # 80004272 <end_op>
    return -1;
    80005718:	557d                	li	a0,-1
    8000571a:	a05d                	j	800057c0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000571c:	00003517          	auipc	a0,0x3
    80005720:	f9c50513          	addi	a0,a0,-100 # 800086b8 <syscalls+0x2b0>
    80005724:	ffffb097          	auipc	ra,0xffffb
    80005728:	e20080e7          	jalr	-480(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000572c:	04c92703          	lw	a4,76(s2)
    80005730:	02000793          	li	a5,32
    80005734:	f6e7f9e3          	bgeu	a5,a4,800056a6 <sys_unlink+0xaa>
    80005738:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000573c:	4741                	li	a4,16
    8000573e:	86ce                	mv	a3,s3
    80005740:	f1840613          	addi	a2,s0,-232
    80005744:	4581                	li	a1,0
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	39c080e7          	jalr	924(ra) # 80003ae4 <readi>
    80005750:	47c1                	li	a5,16
    80005752:	00f51b63          	bne	a0,a5,80005768 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005756:	f1845783          	lhu	a5,-232(s0)
    8000575a:	e7a1                	bnez	a5,800057a2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000575c:	29c1                	addiw	s3,s3,16
    8000575e:	04c92783          	lw	a5,76(s2)
    80005762:	fcf9ede3          	bltu	s3,a5,8000573c <sys_unlink+0x140>
    80005766:	b781                	j	800056a6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005768:	00003517          	auipc	a0,0x3
    8000576c:	f6850513          	addi	a0,a0,-152 # 800086d0 <syscalls+0x2c8>
    80005770:	ffffb097          	auipc	ra,0xffffb
    80005774:	dd4080e7          	jalr	-556(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005778:	00003517          	auipc	a0,0x3
    8000577c:	f7050513          	addi	a0,a0,-144 # 800086e8 <syscalls+0x2e0>
    80005780:	ffffb097          	auipc	ra,0xffffb
    80005784:	dc4080e7          	jalr	-572(ra) # 80000544 <panic>
    dp->nlink--;
    80005788:	04a4d783          	lhu	a5,74(s1)
    8000578c:	37fd                	addiw	a5,a5,-1
    8000578e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	fd2080e7          	jalr	-46(ra) # 80003766 <iupdate>
    8000579c:	b781                	j	800056dc <sys_unlink+0xe0>
    return -1;
    8000579e:	557d                	li	a0,-1
    800057a0:	a005                	j	800057c0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057a2:	854a                	mv	a0,s2
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	2ee080e7          	jalr	750(ra) # 80003a92 <iunlockput>
  iunlockput(dp);
    800057ac:	8526                	mv	a0,s1
    800057ae:	ffffe097          	auipc	ra,0xffffe
    800057b2:	2e4080e7          	jalr	740(ra) # 80003a92 <iunlockput>
  end_op();
    800057b6:	fffff097          	auipc	ra,0xfffff
    800057ba:	abc080e7          	jalr	-1348(ra) # 80004272 <end_op>
  return -1;
    800057be:	557d                	li	a0,-1
}
    800057c0:	70ae                	ld	ra,232(sp)
    800057c2:	740e                	ld	s0,224(sp)
    800057c4:	64ee                	ld	s1,216(sp)
    800057c6:	694e                	ld	s2,208(sp)
    800057c8:	69ae                	ld	s3,200(sp)
    800057ca:	616d                	addi	sp,sp,240
    800057cc:	8082                	ret

00000000800057ce <sys_open>:

uint64
sys_open(void)
{
    800057ce:	7131                	addi	sp,sp,-192
    800057d0:	fd06                	sd	ra,184(sp)
    800057d2:	f922                	sd	s0,176(sp)
    800057d4:	f526                	sd	s1,168(sp)
    800057d6:	f14a                	sd	s2,160(sp)
    800057d8:	ed4e                	sd	s3,152(sp)
    800057da:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800057dc:	f4c40593          	addi	a1,s0,-180
    800057e0:	4505                	li	a0,1
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	4de080e7          	jalr	1246(ra) # 80002cc0 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057ea:	08000613          	li	a2,128
    800057ee:	f5040593          	addi	a1,s0,-176
    800057f2:	4501                	li	a0,0
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	50c080e7          	jalr	1292(ra) # 80002d00 <argstr>
    800057fc:	87aa                	mv	a5,a0
    return -1;
    800057fe:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005800:	0a07c963          	bltz	a5,800058b2 <sys_open+0xe4>

  begin_op();
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	9ee080e7          	jalr	-1554(ra) # 800041f2 <begin_op>

  if(omode & O_CREATE){
    8000580c:	f4c42783          	lw	a5,-180(s0)
    80005810:	2007f793          	andi	a5,a5,512
    80005814:	cfc5                	beqz	a5,800058cc <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005816:	4681                	li	a3,0
    80005818:	4601                	li	a2,0
    8000581a:	4589                	li	a1,2
    8000581c:	f5040513          	addi	a0,s0,-176
    80005820:	00000097          	auipc	ra,0x0
    80005824:	974080e7          	jalr	-1676(ra) # 80005194 <create>
    80005828:	84aa                	mv	s1,a0
    if(ip == 0){
    8000582a:	c959                	beqz	a0,800058c0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000582c:	04449703          	lh	a4,68(s1)
    80005830:	478d                	li	a5,3
    80005832:	00f71763          	bne	a4,a5,80005840 <sys_open+0x72>
    80005836:	0464d703          	lhu	a4,70(s1)
    8000583a:	47a5                	li	a5,9
    8000583c:	0ce7ed63          	bltu	a5,a4,80005916 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	dc2080e7          	jalr	-574(ra) # 80004602 <filealloc>
    80005848:	89aa                	mv	s3,a0
    8000584a:	10050363          	beqz	a0,80005950 <sys_open+0x182>
    8000584e:	00000097          	auipc	ra,0x0
    80005852:	904080e7          	jalr	-1788(ra) # 80005152 <fdalloc>
    80005856:	892a                	mv	s2,a0
    80005858:	0e054763          	bltz	a0,80005946 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000585c:	04449703          	lh	a4,68(s1)
    80005860:	478d                	li	a5,3
    80005862:	0cf70563          	beq	a4,a5,8000592c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005866:	4789                	li	a5,2
    80005868:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000586c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005870:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005874:	f4c42783          	lw	a5,-180(s0)
    80005878:	0017c713          	xori	a4,a5,1
    8000587c:	8b05                	andi	a4,a4,1
    8000587e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005882:	0037f713          	andi	a4,a5,3
    80005886:	00e03733          	snez	a4,a4
    8000588a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000588e:	4007f793          	andi	a5,a5,1024
    80005892:	c791                	beqz	a5,8000589e <sys_open+0xd0>
    80005894:	04449703          	lh	a4,68(s1)
    80005898:	4789                	li	a5,2
    8000589a:	0af70063          	beq	a4,a5,8000593a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000589e:	8526                	mv	a0,s1
    800058a0:	ffffe097          	auipc	ra,0xffffe
    800058a4:	052080e7          	jalr	82(ra) # 800038f2 <iunlock>
  end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	9ca080e7          	jalr	-1590(ra) # 80004272 <end_op>

  return fd;
    800058b0:	854a                	mv	a0,s2
}
    800058b2:	70ea                	ld	ra,184(sp)
    800058b4:	744a                	ld	s0,176(sp)
    800058b6:	74aa                	ld	s1,168(sp)
    800058b8:	790a                	ld	s2,160(sp)
    800058ba:	69ea                	ld	s3,152(sp)
    800058bc:	6129                	addi	sp,sp,192
    800058be:	8082                	ret
      end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	9b2080e7          	jalr	-1614(ra) # 80004272 <end_op>
      return -1;
    800058c8:	557d                	li	a0,-1
    800058ca:	b7e5                	j	800058b2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058cc:	f5040513          	addi	a0,s0,-176
    800058d0:	ffffe097          	auipc	ra,0xffffe
    800058d4:	706080e7          	jalr	1798(ra) # 80003fd6 <namei>
    800058d8:	84aa                	mv	s1,a0
    800058da:	c905                	beqz	a0,8000590a <sys_open+0x13c>
    ilock(ip);
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	f54080e7          	jalr	-172(ra) # 80003830 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058e4:	04449703          	lh	a4,68(s1)
    800058e8:	4785                	li	a5,1
    800058ea:	f4f711e3          	bne	a4,a5,8000582c <sys_open+0x5e>
    800058ee:	f4c42783          	lw	a5,-180(s0)
    800058f2:	d7b9                	beqz	a5,80005840 <sys_open+0x72>
      iunlockput(ip);
    800058f4:	8526                	mv	a0,s1
    800058f6:	ffffe097          	auipc	ra,0xffffe
    800058fa:	19c080e7          	jalr	412(ra) # 80003a92 <iunlockput>
      end_op();
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	974080e7          	jalr	-1676(ra) # 80004272 <end_op>
      return -1;
    80005906:	557d                	li	a0,-1
    80005908:	b76d                	j	800058b2 <sys_open+0xe4>
      end_op();
    8000590a:	fffff097          	auipc	ra,0xfffff
    8000590e:	968080e7          	jalr	-1688(ra) # 80004272 <end_op>
      return -1;
    80005912:	557d                	li	a0,-1
    80005914:	bf79                	j	800058b2 <sys_open+0xe4>
    iunlockput(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	17a080e7          	jalr	378(ra) # 80003a92 <iunlockput>
    end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	952080e7          	jalr	-1710(ra) # 80004272 <end_op>
    return -1;
    80005928:	557d                	li	a0,-1
    8000592a:	b761                	j	800058b2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000592c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005930:	04649783          	lh	a5,70(s1)
    80005934:	02f99223          	sh	a5,36(s3)
    80005938:	bf25                	j	80005870 <sys_open+0xa2>
    itrunc(ip);
    8000593a:	8526                	mv	a0,s1
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	002080e7          	jalr	2(ra) # 8000393e <itrunc>
    80005944:	bfa9                	j	8000589e <sys_open+0xd0>
      fileclose(f);
    80005946:	854e                	mv	a0,s3
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	d76080e7          	jalr	-650(ra) # 800046be <fileclose>
    iunlockput(ip);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	140080e7          	jalr	320(ra) # 80003a92 <iunlockput>
    end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	918080e7          	jalr	-1768(ra) # 80004272 <end_op>
    return -1;
    80005962:	557d                	li	a0,-1
    80005964:	b7b9                	j	800058b2 <sys_open+0xe4>

0000000080005966 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005966:	7175                	addi	sp,sp,-144
    80005968:	e506                	sd	ra,136(sp)
    8000596a:	e122                	sd	s0,128(sp)
    8000596c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	884080e7          	jalr	-1916(ra) # 800041f2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005976:	08000613          	li	a2,128
    8000597a:	f7040593          	addi	a1,s0,-144
    8000597e:	4501                	li	a0,0
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	380080e7          	jalr	896(ra) # 80002d00 <argstr>
    80005988:	02054963          	bltz	a0,800059ba <sys_mkdir+0x54>
    8000598c:	4681                	li	a3,0
    8000598e:	4601                	li	a2,0
    80005990:	4585                	li	a1,1
    80005992:	f7040513          	addi	a0,s0,-144
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	7fe080e7          	jalr	2046(ra) # 80005194 <create>
    8000599e:	cd11                	beqz	a0,800059ba <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	0f2080e7          	jalr	242(ra) # 80003a92 <iunlockput>
  end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	8ca080e7          	jalr	-1846(ra) # 80004272 <end_op>
  return 0;
    800059b0:	4501                	li	a0,0
}
    800059b2:	60aa                	ld	ra,136(sp)
    800059b4:	640a                	ld	s0,128(sp)
    800059b6:	6149                	addi	sp,sp,144
    800059b8:	8082                	ret
    end_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	8b8080e7          	jalr	-1864(ra) # 80004272 <end_op>
    return -1;
    800059c2:	557d                	li	a0,-1
    800059c4:	b7fd                	j	800059b2 <sys_mkdir+0x4c>

00000000800059c6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800059c6:	7135                	addi	sp,sp,-160
    800059c8:	ed06                	sd	ra,152(sp)
    800059ca:	e922                	sd	s0,144(sp)
    800059cc:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	824080e7          	jalr	-2012(ra) # 800041f2 <begin_op>
  argint(1, &major);
    800059d6:	f6c40593          	addi	a1,s0,-148
    800059da:	4505                	li	a0,1
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	2e4080e7          	jalr	740(ra) # 80002cc0 <argint>
  argint(2, &minor);
    800059e4:	f6840593          	addi	a1,s0,-152
    800059e8:	4509                	li	a0,2
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	2d6080e7          	jalr	726(ra) # 80002cc0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059f2:	08000613          	li	a2,128
    800059f6:	f7040593          	addi	a1,s0,-144
    800059fa:	4501                	li	a0,0
    800059fc:	ffffd097          	auipc	ra,0xffffd
    80005a00:	304080e7          	jalr	772(ra) # 80002d00 <argstr>
    80005a04:	02054b63          	bltz	a0,80005a3a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a08:	f6841683          	lh	a3,-152(s0)
    80005a0c:	f6c41603          	lh	a2,-148(s0)
    80005a10:	458d                	li	a1,3
    80005a12:	f7040513          	addi	a0,s0,-144
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	77e080e7          	jalr	1918(ra) # 80005194 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a1e:	cd11                	beqz	a0,80005a3a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	072080e7          	jalr	114(ra) # 80003a92 <iunlockput>
  end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	84a080e7          	jalr	-1974(ra) # 80004272 <end_op>
  return 0;
    80005a30:	4501                	li	a0,0
}
    80005a32:	60ea                	ld	ra,152(sp)
    80005a34:	644a                	ld	s0,144(sp)
    80005a36:	610d                	addi	sp,sp,160
    80005a38:	8082                	ret
    end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	838080e7          	jalr	-1992(ra) # 80004272 <end_op>
    return -1;
    80005a42:	557d                	li	a0,-1
    80005a44:	b7fd                	j	80005a32 <sys_mknod+0x6c>

0000000080005a46 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a46:	7135                	addi	sp,sp,-160
    80005a48:	ed06                	sd	ra,152(sp)
    80005a4a:	e922                	sd	s0,144(sp)
    80005a4c:	e526                	sd	s1,136(sp)
    80005a4e:	e14a                	sd	s2,128(sp)
    80005a50:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a52:	ffffc097          	auipc	ra,0xffffc
    80005a56:	0c2080e7          	jalr	194(ra) # 80001b14 <myproc>
    80005a5a:	892a                	mv	s2,a0
  
  begin_op();
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	796080e7          	jalr	1942(ra) # 800041f2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a64:	08000613          	li	a2,128
    80005a68:	f6040593          	addi	a1,s0,-160
    80005a6c:	4501                	li	a0,0
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	292080e7          	jalr	658(ra) # 80002d00 <argstr>
    80005a76:	04054b63          	bltz	a0,80005acc <sys_chdir+0x86>
    80005a7a:	f6040513          	addi	a0,s0,-160
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	558080e7          	jalr	1368(ra) # 80003fd6 <namei>
    80005a86:	84aa                	mv	s1,a0
    80005a88:	c131                	beqz	a0,80005acc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	da6080e7          	jalr	-602(ra) # 80003830 <ilock>
  if(ip->type != T_DIR){
    80005a92:	04449703          	lh	a4,68(s1)
    80005a96:	4785                	li	a5,1
    80005a98:	04f71063          	bne	a4,a5,80005ad8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	e54080e7          	jalr	-428(ra) # 800038f2 <iunlock>
  iput(p->cwd);
    80005aa6:	15093503          	ld	a0,336(s2)
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	f40080e7          	jalr	-192(ra) # 800039ea <iput>
  end_op();
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	7c0080e7          	jalr	1984(ra) # 80004272 <end_op>
  p->cwd = ip;
    80005aba:	14993823          	sd	s1,336(s2)
  return 0;
    80005abe:	4501                	li	a0,0
}
    80005ac0:	60ea                	ld	ra,152(sp)
    80005ac2:	644a                	ld	s0,144(sp)
    80005ac4:	64aa                	ld	s1,136(sp)
    80005ac6:	690a                	ld	s2,128(sp)
    80005ac8:	610d                	addi	sp,sp,160
    80005aca:	8082                	ret
    end_op();
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	7a6080e7          	jalr	1958(ra) # 80004272 <end_op>
    return -1;
    80005ad4:	557d                	li	a0,-1
    80005ad6:	b7ed                	j	80005ac0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	fb8080e7          	jalr	-72(ra) # 80003a92 <iunlockput>
    end_op();
    80005ae2:	ffffe097          	auipc	ra,0xffffe
    80005ae6:	790080e7          	jalr	1936(ra) # 80004272 <end_op>
    return -1;
    80005aea:	557d                	li	a0,-1
    80005aec:	bfd1                	j	80005ac0 <sys_chdir+0x7a>

0000000080005aee <sys_exec>:

uint64
sys_exec(void)
{
    80005aee:	7145                	addi	sp,sp,-464
    80005af0:	e786                	sd	ra,456(sp)
    80005af2:	e3a2                	sd	s0,448(sp)
    80005af4:	ff26                	sd	s1,440(sp)
    80005af6:	fb4a                	sd	s2,432(sp)
    80005af8:	f74e                	sd	s3,424(sp)
    80005afa:	f352                	sd	s4,416(sp)
    80005afc:	ef56                	sd	s5,408(sp)
    80005afe:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b00:	e3840593          	addi	a1,s0,-456
    80005b04:	4505                	li	a0,1
    80005b06:	ffffd097          	auipc	ra,0xffffd
    80005b0a:	1da080e7          	jalr	474(ra) # 80002ce0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b0e:	08000613          	li	a2,128
    80005b12:	f4040593          	addi	a1,s0,-192
    80005b16:	4501                	li	a0,0
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	1e8080e7          	jalr	488(ra) # 80002d00 <argstr>
    80005b20:	87aa                	mv	a5,a0
    return -1;
    80005b22:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b24:	0c07c263          	bltz	a5,80005be8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b28:	10000613          	li	a2,256
    80005b2c:	4581                	li	a1,0
    80005b2e:	e4040513          	addi	a0,s0,-448
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	1b4080e7          	jalr	436(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b3a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b3e:	89a6                	mv	s3,s1
    80005b40:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b42:	02000a13          	li	s4,32
    80005b46:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b4a:	00391513          	slli	a0,s2,0x3
    80005b4e:	e3040593          	addi	a1,s0,-464
    80005b52:	e3843783          	ld	a5,-456(s0)
    80005b56:	953e                	add	a0,a0,a5
    80005b58:	ffffd097          	auipc	ra,0xffffd
    80005b5c:	0ca080e7          	jalr	202(ra) # 80002c22 <fetchaddr>
    80005b60:	02054a63          	bltz	a0,80005b94 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b64:	e3043783          	ld	a5,-464(s0)
    80005b68:	c3b9                	beqz	a5,80005bae <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b6a:	ffffb097          	auipc	ra,0xffffb
    80005b6e:	f90080e7          	jalr	-112(ra) # 80000afa <kalloc>
    80005b72:	85aa                	mv	a1,a0
    80005b74:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b78:	cd11                	beqz	a0,80005b94 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b7a:	6605                	lui	a2,0x1
    80005b7c:	e3043503          	ld	a0,-464(s0)
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	0f4080e7          	jalr	244(ra) # 80002c74 <fetchstr>
    80005b88:	00054663          	bltz	a0,80005b94 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b8c:	0905                	addi	s2,s2,1
    80005b8e:	09a1                	addi	s3,s3,8
    80005b90:	fb491be3          	bne	s2,s4,80005b46 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b94:	10048913          	addi	s2,s1,256
    80005b98:	6088                	ld	a0,0(s1)
    80005b9a:	c531                	beqz	a0,80005be6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b9c:	ffffb097          	auipc	ra,0xffffb
    80005ba0:	e62080e7          	jalr	-414(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba4:	04a1                	addi	s1,s1,8
    80005ba6:	ff2499e3          	bne	s1,s2,80005b98 <sys_exec+0xaa>
  return -1;
    80005baa:	557d                	li	a0,-1
    80005bac:	a835                	j	80005be8 <sys_exec+0xfa>
      argv[i] = 0;
    80005bae:	0a8e                	slli	s5,s5,0x3
    80005bb0:	fc040793          	addi	a5,s0,-64
    80005bb4:	9abe                	add	s5,s5,a5
    80005bb6:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bba:	e4040593          	addi	a1,s0,-448
    80005bbe:	f4040513          	addi	a0,s0,-192
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	184080e7          	jalr	388(ra) # 80004d46 <exec>
    80005bca:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bcc:	10048993          	addi	s3,s1,256
    80005bd0:	6088                	ld	a0,0(s1)
    80005bd2:	c901                	beqz	a0,80005be2 <sys_exec+0xf4>
    kfree(argv[i]);
    80005bd4:	ffffb097          	auipc	ra,0xffffb
    80005bd8:	e2a080e7          	jalr	-470(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bdc:	04a1                	addi	s1,s1,8
    80005bde:	ff3499e3          	bne	s1,s3,80005bd0 <sys_exec+0xe2>
  return ret;
    80005be2:	854a                	mv	a0,s2
    80005be4:	a011                	j	80005be8 <sys_exec+0xfa>
  return -1;
    80005be6:	557d                	li	a0,-1
}
    80005be8:	60be                	ld	ra,456(sp)
    80005bea:	641e                	ld	s0,448(sp)
    80005bec:	74fa                	ld	s1,440(sp)
    80005bee:	795a                	ld	s2,432(sp)
    80005bf0:	79ba                	ld	s3,424(sp)
    80005bf2:	7a1a                	ld	s4,416(sp)
    80005bf4:	6afa                	ld	s5,408(sp)
    80005bf6:	6179                	addi	sp,sp,464
    80005bf8:	8082                	ret

0000000080005bfa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bfa:	7139                	addi	sp,sp,-64
    80005bfc:	fc06                	sd	ra,56(sp)
    80005bfe:	f822                	sd	s0,48(sp)
    80005c00:	f426                	sd	s1,40(sp)
    80005c02:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c04:	ffffc097          	auipc	ra,0xffffc
    80005c08:	f10080e7          	jalr	-240(ra) # 80001b14 <myproc>
    80005c0c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c0e:	fd840593          	addi	a1,s0,-40
    80005c12:	4501                	li	a0,0
    80005c14:	ffffd097          	auipc	ra,0xffffd
    80005c18:	0cc080e7          	jalr	204(ra) # 80002ce0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c1c:	fc840593          	addi	a1,s0,-56
    80005c20:	fd040513          	addi	a0,s0,-48
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	dca080e7          	jalr	-566(ra) # 800049ee <pipealloc>
    return -1;
    80005c2c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c2e:	0c054463          	bltz	a0,80005cf6 <sys_pipe+0xfc>
  fd0 = -1;
    80005c32:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c36:	fd043503          	ld	a0,-48(s0)
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	518080e7          	jalr	1304(ra) # 80005152 <fdalloc>
    80005c42:	fca42223          	sw	a0,-60(s0)
    80005c46:	08054b63          	bltz	a0,80005cdc <sys_pipe+0xe2>
    80005c4a:	fc843503          	ld	a0,-56(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	504080e7          	jalr	1284(ra) # 80005152 <fdalloc>
    80005c56:	fca42023          	sw	a0,-64(s0)
    80005c5a:	06054863          	bltz	a0,80005cca <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c5e:	4691                	li	a3,4
    80005c60:	fc440613          	addi	a2,s0,-60
    80005c64:	fd843583          	ld	a1,-40(s0)
    80005c68:	68a8                	ld	a0,80(s1)
    80005c6a:	ffffc097          	auipc	ra,0xffffc
    80005c6e:	b68080e7          	jalr	-1176(ra) # 800017d2 <copyout>
    80005c72:	02054063          	bltz	a0,80005c92 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c76:	4691                	li	a3,4
    80005c78:	fc040613          	addi	a2,s0,-64
    80005c7c:	fd843583          	ld	a1,-40(s0)
    80005c80:	0591                	addi	a1,a1,4
    80005c82:	68a8                	ld	a0,80(s1)
    80005c84:	ffffc097          	auipc	ra,0xffffc
    80005c88:	b4e080e7          	jalr	-1202(ra) # 800017d2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c8c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c8e:	06055463          	bgez	a0,80005cf6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c92:	fc442783          	lw	a5,-60(s0)
    80005c96:	07e9                	addi	a5,a5,26
    80005c98:	078e                	slli	a5,a5,0x3
    80005c9a:	97a6                	add	a5,a5,s1
    80005c9c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ca0:	fc042503          	lw	a0,-64(s0)
    80005ca4:	0569                	addi	a0,a0,26
    80005ca6:	050e                	slli	a0,a0,0x3
    80005ca8:	94aa                	add	s1,s1,a0
    80005caa:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cae:	fd043503          	ld	a0,-48(s0)
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	a0c080e7          	jalr	-1524(ra) # 800046be <fileclose>
    fileclose(wf);
    80005cba:	fc843503          	ld	a0,-56(s0)
    80005cbe:	fffff097          	auipc	ra,0xfffff
    80005cc2:	a00080e7          	jalr	-1536(ra) # 800046be <fileclose>
    return -1;
    80005cc6:	57fd                	li	a5,-1
    80005cc8:	a03d                	j	80005cf6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005cca:	fc442783          	lw	a5,-60(s0)
    80005cce:	0007c763          	bltz	a5,80005cdc <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005cd2:	07e9                	addi	a5,a5,26
    80005cd4:	078e                	slli	a5,a5,0x3
    80005cd6:	94be                	add	s1,s1,a5
    80005cd8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cdc:	fd043503          	ld	a0,-48(s0)
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	9de080e7          	jalr	-1570(ra) # 800046be <fileclose>
    fileclose(wf);
    80005ce8:	fc843503          	ld	a0,-56(s0)
    80005cec:	fffff097          	auipc	ra,0xfffff
    80005cf0:	9d2080e7          	jalr	-1582(ra) # 800046be <fileclose>
    return -1;
    80005cf4:	57fd                	li	a5,-1
}
    80005cf6:	853e                	mv	a0,a5
    80005cf8:	70e2                	ld	ra,56(sp)
    80005cfa:	7442                	ld	s0,48(sp)
    80005cfc:	74a2                	ld	s1,40(sp)
    80005cfe:	6121                	addi	sp,sp,64
    80005d00:	8082                	ret
	...

0000000080005d10 <kernelvec>:
    80005d10:	7111                	addi	sp,sp,-256
    80005d12:	e006                	sd	ra,0(sp)
    80005d14:	e40a                	sd	sp,8(sp)
    80005d16:	e80e                	sd	gp,16(sp)
    80005d18:	ec12                	sd	tp,24(sp)
    80005d1a:	f016                	sd	t0,32(sp)
    80005d1c:	f41a                	sd	t1,40(sp)
    80005d1e:	f81e                	sd	t2,48(sp)
    80005d20:	fc22                	sd	s0,56(sp)
    80005d22:	e0a6                	sd	s1,64(sp)
    80005d24:	e4aa                	sd	a0,72(sp)
    80005d26:	e8ae                	sd	a1,80(sp)
    80005d28:	ecb2                	sd	a2,88(sp)
    80005d2a:	f0b6                	sd	a3,96(sp)
    80005d2c:	f4ba                	sd	a4,104(sp)
    80005d2e:	f8be                	sd	a5,112(sp)
    80005d30:	fcc2                	sd	a6,120(sp)
    80005d32:	e146                	sd	a7,128(sp)
    80005d34:	e54a                	sd	s2,136(sp)
    80005d36:	e94e                	sd	s3,144(sp)
    80005d38:	ed52                	sd	s4,152(sp)
    80005d3a:	f156                	sd	s5,160(sp)
    80005d3c:	f55a                	sd	s6,168(sp)
    80005d3e:	f95e                	sd	s7,176(sp)
    80005d40:	fd62                	sd	s8,184(sp)
    80005d42:	e1e6                	sd	s9,192(sp)
    80005d44:	e5ea                	sd	s10,200(sp)
    80005d46:	e9ee                	sd	s11,208(sp)
    80005d48:	edf2                	sd	t3,216(sp)
    80005d4a:	f1f6                	sd	t4,224(sp)
    80005d4c:	f5fa                	sd	t5,232(sp)
    80005d4e:	f9fe                	sd	t6,240(sp)
    80005d50:	d9ffc0ef          	jal	ra,80002aee <kerneltrap>
    80005d54:	6082                	ld	ra,0(sp)
    80005d56:	6122                	ld	sp,8(sp)
    80005d58:	61c2                	ld	gp,16(sp)
    80005d5a:	7282                	ld	t0,32(sp)
    80005d5c:	7322                	ld	t1,40(sp)
    80005d5e:	73c2                	ld	t2,48(sp)
    80005d60:	7462                	ld	s0,56(sp)
    80005d62:	6486                	ld	s1,64(sp)
    80005d64:	6526                	ld	a0,72(sp)
    80005d66:	65c6                	ld	a1,80(sp)
    80005d68:	6666                	ld	a2,88(sp)
    80005d6a:	7686                	ld	a3,96(sp)
    80005d6c:	7726                	ld	a4,104(sp)
    80005d6e:	77c6                	ld	a5,112(sp)
    80005d70:	7866                	ld	a6,120(sp)
    80005d72:	688a                	ld	a7,128(sp)
    80005d74:	692a                	ld	s2,136(sp)
    80005d76:	69ca                	ld	s3,144(sp)
    80005d78:	6a6a                	ld	s4,152(sp)
    80005d7a:	7a8a                	ld	s5,160(sp)
    80005d7c:	7b2a                	ld	s6,168(sp)
    80005d7e:	7bca                	ld	s7,176(sp)
    80005d80:	7c6a                	ld	s8,184(sp)
    80005d82:	6c8e                	ld	s9,192(sp)
    80005d84:	6d2e                	ld	s10,200(sp)
    80005d86:	6dce                	ld	s11,208(sp)
    80005d88:	6e6e                	ld	t3,216(sp)
    80005d8a:	7e8e                	ld	t4,224(sp)
    80005d8c:	7f2e                	ld	t5,232(sp)
    80005d8e:	7fce                	ld	t6,240(sp)
    80005d90:	6111                	addi	sp,sp,256
    80005d92:	10200073          	sret
    80005d96:	00000013          	nop
    80005d9a:	00000013          	nop
    80005d9e:	0001                	nop

0000000080005da0 <timervec>:
    80005da0:	34051573          	csrrw	a0,mscratch,a0
    80005da4:	e10c                	sd	a1,0(a0)
    80005da6:	e510                	sd	a2,8(a0)
    80005da8:	e914                	sd	a3,16(a0)
    80005daa:	6d0c                	ld	a1,24(a0)
    80005dac:	7110                	ld	a2,32(a0)
    80005dae:	6194                	ld	a3,0(a1)
    80005db0:	96b2                	add	a3,a3,a2
    80005db2:	e194                	sd	a3,0(a1)
    80005db4:	4589                	li	a1,2
    80005db6:	14459073          	csrw	sip,a1
    80005dba:	6914                	ld	a3,16(a0)
    80005dbc:	6510                	ld	a2,8(a0)
    80005dbe:	610c                	ld	a1,0(a0)
    80005dc0:	34051573          	csrrw	a0,mscratch,a0
    80005dc4:	30200073          	mret
	...

0000000080005dca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dca:	1141                	addi	sp,sp,-16
    80005dcc:	e422                	sd	s0,8(sp)
    80005dce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dd0:	0c0007b7          	lui	a5,0xc000
    80005dd4:	4705                	li	a4,1
    80005dd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dd8:	c3d8                	sw	a4,4(a5)
}
    80005dda:	6422                	ld	s0,8(sp)
    80005ddc:	0141                	addi	sp,sp,16
    80005dde:	8082                	ret

0000000080005de0 <plicinithart>:

void
plicinithart(void)
{
    80005de0:	1141                	addi	sp,sp,-16
    80005de2:	e406                	sd	ra,8(sp)
    80005de4:	e022                	sd	s0,0(sp)
    80005de6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	d00080e7          	jalr	-768(ra) # 80001ae8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005df0:	0085171b          	slliw	a4,a0,0x8
    80005df4:	0c0027b7          	lui	a5,0xc002
    80005df8:	97ba                	add	a5,a5,a4
    80005dfa:	40200713          	li	a4,1026
    80005dfe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e02:	00d5151b          	slliw	a0,a0,0xd
    80005e06:	0c2017b7          	lui	a5,0xc201
    80005e0a:	953e                	add	a0,a0,a5
    80005e0c:	00052023          	sw	zero,0(a0)
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret

0000000080005e18 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e18:	1141                	addi	sp,sp,-16
    80005e1a:	e406                	sd	ra,8(sp)
    80005e1c:	e022                	sd	s0,0(sp)
    80005e1e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e20:	ffffc097          	auipc	ra,0xffffc
    80005e24:	cc8080e7          	jalr	-824(ra) # 80001ae8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e28:	00d5179b          	slliw	a5,a0,0xd
    80005e2c:	0c201537          	lui	a0,0xc201
    80005e30:	953e                	add	a0,a0,a5
  return irq;
}
    80005e32:	4148                	lw	a0,4(a0)
    80005e34:	60a2                	ld	ra,8(sp)
    80005e36:	6402                	ld	s0,0(sp)
    80005e38:	0141                	addi	sp,sp,16
    80005e3a:	8082                	ret

0000000080005e3c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e3c:	1101                	addi	sp,sp,-32
    80005e3e:	ec06                	sd	ra,24(sp)
    80005e40:	e822                	sd	s0,16(sp)
    80005e42:	e426                	sd	s1,8(sp)
    80005e44:	1000                	addi	s0,sp,32
    80005e46:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	ca0080e7          	jalr	-864(ra) # 80001ae8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e50:	00d5151b          	slliw	a0,a0,0xd
    80005e54:	0c2017b7          	lui	a5,0xc201
    80005e58:	97aa                	add	a5,a5,a0
    80005e5a:	c3c4                	sw	s1,4(a5)
}
    80005e5c:	60e2                	ld	ra,24(sp)
    80005e5e:	6442                	ld	s0,16(sp)
    80005e60:	64a2                	ld	s1,8(sp)
    80005e62:	6105                	addi	sp,sp,32
    80005e64:	8082                	ret

0000000080005e66 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e66:	1141                	addi	sp,sp,-16
    80005e68:	e406                	sd	ra,8(sp)
    80005e6a:	e022                	sd	s0,0(sp)
    80005e6c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e6e:	479d                	li	a5,7
    80005e70:	04a7cc63          	blt	a5,a0,80005ec8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e74:	0001c797          	auipc	a5,0x1c
    80005e78:	d6c78793          	addi	a5,a5,-660 # 80021be0 <disk>
    80005e7c:	97aa                	add	a5,a5,a0
    80005e7e:	0187c783          	lbu	a5,24(a5)
    80005e82:	ebb9                	bnez	a5,80005ed8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e84:	00451613          	slli	a2,a0,0x4
    80005e88:	0001c797          	auipc	a5,0x1c
    80005e8c:	d5878793          	addi	a5,a5,-680 # 80021be0 <disk>
    80005e90:	6394                	ld	a3,0(a5)
    80005e92:	96b2                	add	a3,a3,a2
    80005e94:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e98:	6398                	ld	a4,0(a5)
    80005e9a:	9732                	add	a4,a4,a2
    80005e9c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005ea0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005ea4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005ea8:	953e                	add	a0,a0,a5
    80005eaa:	4785                	li	a5,1
    80005eac:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005eb0:	0001c517          	auipc	a0,0x1c
    80005eb4:	d4850513          	addi	a0,a0,-696 # 80021bf8 <disk+0x18>
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	3d0080e7          	jalr	976(ra) # 80002288 <wakeup>
}
    80005ec0:	60a2                	ld	ra,8(sp)
    80005ec2:	6402                	ld	s0,0(sp)
    80005ec4:	0141                	addi	sp,sp,16
    80005ec6:	8082                	ret
    panic("free_desc 1");
    80005ec8:	00003517          	auipc	a0,0x3
    80005ecc:	83050513          	addi	a0,a0,-2000 # 800086f8 <syscalls+0x2f0>
    80005ed0:	ffffa097          	auipc	ra,0xffffa
    80005ed4:	674080e7          	jalr	1652(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005ed8:	00003517          	auipc	a0,0x3
    80005edc:	83050513          	addi	a0,a0,-2000 # 80008708 <syscalls+0x300>
    80005ee0:	ffffa097          	auipc	ra,0xffffa
    80005ee4:	664080e7          	jalr	1636(ra) # 80000544 <panic>

0000000080005ee8 <virtio_disk_init>:
{
    80005ee8:	1101                	addi	sp,sp,-32
    80005eea:	ec06                	sd	ra,24(sp)
    80005eec:	e822                	sd	s0,16(sp)
    80005eee:	e426                	sd	s1,8(sp)
    80005ef0:	e04a                	sd	s2,0(sp)
    80005ef2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ef4:	00003597          	auipc	a1,0x3
    80005ef8:	82458593          	addi	a1,a1,-2012 # 80008718 <syscalls+0x310>
    80005efc:	0001c517          	auipc	a0,0x1c
    80005f00:	e0c50513          	addi	a0,a0,-500 # 80021d08 <disk+0x128>
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	c56080e7          	jalr	-938(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f0c:	100017b7          	lui	a5,0x10001
    80005f10:	4398                	lw	a4,0(a5)
    80005f12:	2701                	sext.w	a4,a4
    80005f14:	747277b7          	lui	a5,0x74727
    80005f18:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f1c:	14f71e63          	bne	a4,a5,80006078 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f20:	100017b7          	lui	a5,0x10001
    80005f24:	43dc                	lw	a5,4(a5)
    80005f26:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f28:	4709                	li	a4,2
    80005f2a:	14e79763          	bne	a5,a4,80006078 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f2e:	100017b7          	lui	a5,0x10001
    80005f32:	479c                	lw	a5,8(a5)
    80005f34:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f36:	14e79163          	bne	a5,a4,80006078 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f3a:	100017b7          	lui	a5,0x10001
    80005f3e:	47d8                	lw	a4,12(a5)
    80005f40:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f42:	554d47b7          	lui	a5,0x554d4
    80005f46:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f4a:	12f71763          	bne	a4,a5,80006078 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f4e:	100017b7          	lui	a5,0x10001
    80005f52:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f56:	4705                	li	a4,1
    80005f58:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f5a:	470d                	li	a4,3
    80005f5c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f5e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f60:	c7ffe737          	lui	a4,0xc7ffe
    80005f64:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdca3f>
    80005f68:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f6a:	2701                	sext.w	a4,a4
    80005f6c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f6e:	472d                	li	a4,11
    80005f70:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f72:	0707a903          	lw	s2,112(a5)
    80005f76:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f78:	00897793          	andi	a5,s2,8
    80005f7c:	10078663          	beqz	a5,80006088 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f80:	100017b7          	lui	a5,0x10001
    80005f84:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f88:	43fc                	lw	a5,68(a5)
    80005f8a:	2781                	sext.w	a5,a5
    80005f8c:	10079663          	bnez	a5,80006098 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f90:	100017b7          	lui	a5,0x10001
    80005f94:	5bdc                	lw	a5,52(a5)
    80005f96:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f98:	10078863          	beqz	a5,800060a8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005f9c:	471d                	li	a4,7
    80005f9e:	10f77d63          	bgeu	a4,a5,800060b8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	b58080e7          	jalr	-1192(ra) # 80000afa <kalloc>
    80005faa:	0001c497          	auipc	s1,0x1c
    80005fae:	c3648493          	addi	s1,s1,-970 # 80021be0 <disk>
    80005fb2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005fb4:	ffffb097          	auipc	ra,0xffffb
    80005fb8:	b46080e7          	jalr	-1210(ra) # 80000afa <kalloc>
    80005fbc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005fbe:	ffffb097          	auipc	ra,0xffffb
    80005fc2:	b3c080e7          	jalr	-1220(ra) # 80000afa <kalloc>
    80005fc6:	87aa                	mv	a5,a0
    80005fc8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005fca:	6088                	ld	a0,0(s1)
    80005fcc:	cd75                	beqz	a0,800060c8 <virtio_disk_init+0x1e0>
    80005fce:	0001c717          	auipc	a4,0x1c
    80005fd2:	c1a73703          	ld	a4,-998(a4) # 80021be8 <disk+0x8>
    80005fd6:	cb6d                	beqz	a4,800060c8 <virtio_disk_init+0x1e0>
    80005fd8:	cbe5                	beqz	a5,800060c8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005fda:	6605                	lui	a2,0x1
    80005fdc:	4581                	li	a1,0
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	d08080e7          	jalr	-760(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005fe6:	0001c497          	auipc	s1,0x1c
    80005fea:	bfa48493          	addi	s1,s1,-1030 # 80021be0 <disk>
    80005fee:	6605                	lui	a2,0x1
    80005ff0:	4581                	li	a1,0
    80005ff2:	6488                	ld	a0,8(s1)
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	cf2080e7          	jalr	-782(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005ffc:	6605                	lui	a2,0x1
    80005ffe:	4581                	li	a1,0
    80006000:	6888                	ld	a0,16(s1)
    80006002:	ffffb097          	auipc	ra,0xffffb
    80006006:	ce4080e7          	jalr	-796(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000600a:	100017b7          	lui	a5,0x10001
    8000600e:	4721                	li	a4,8
    80006010:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006012:	4098                	lw	a4,0(s1)
    80006014:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006018:	40d8                	lw	a4,4(s1)
    8000601a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000601e:	6498                	ld	a4,8(s1)
    80006020:	0007069b          	sext.w	a3,a4
    80006024:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006028:	9701                	srai	a4,a4,0x20
    8000602a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000602e:	6898                	ld	a4,16(s1)
    80006030:	0007069b          	sext.w	a3,a4
    80006034:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006038:	9701                	srai	a4,a4,0x20
    8000603a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000603e:	4685                	li	a3,1
    80006040:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006042:	4705                	li	a4,1
    80006044:	00d48c23          	sb	a3,24(s1)
    80006048:	00e48ca3          	sb	a4,25(s1)
    8000604c:	00e48d23          	sb	a4,26(s1)
    80006050:	00e48da3          	sb	a4,27(s1)
    80006054:	00e48e23          	sb	a4,28(s1)
    80006058:	00e48ea3          	sb	a4,29(s1)
    8000605c:	00e48f23          	sb	a4,30(s1)
    80006060:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006064:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006068:	0727a823          	sw	s2,112(a5)
}
    8000606c:	60e2                	ld	ra,24(sp)
    8000606e:	6442                	ld	s0,16(sp)
    80006070:	64a2                	ld	s1,8(sp)
    80006072:	6902                	ld	s2,0(sp)
    80006074:	6105                	addi	sp,sp,32
    80006076:	8082                	ret
    panic("could not find virtio disk");
    80006078:	00002517          	auipc	a0,0x2
    8000607c:	6b050513          	addi	a0,a0,1712 # 80008728 <syscalls+0x320>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4c4080e7          	jalr	1220(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	6c050513          	addi	a0,a0,1728 # 80008748 <syscalls+0x340>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b4080e7          	jalr	1204(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006098:	00002517          	auipc	a0,0x2
    8000609c:	6d050513          	addi	a0,a0,1744 # 80008768 <syscalls+0x360>
    800060a0:	ffffa097          	auipc	ra,0xffffa
    800060a4:	4a4080e7          	jalr	1188(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800060a8:	00002517          	auipc	a0,0x2
    800060ac:	6e050513          	addi	a0,a0,1760 # 80008788 <syscalls+0x380>
    800060b0:	ffffa097          	auipc	ra,0xffffa
    800060b4:	494080e7          	jalr	1172(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800060b8:	00002517          	auipc	a0,0x2
    800060bc:	6f050513          	addi	a0,a0,1776 # 800087a8 <syscalls+0x3a0>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	484080e7          	jalr	1156(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800060c8:	00002517          	auipc	a0,0x2
    800060cc:	70050513          	addi	a0,a0,1792 # 800087c8 <syscalls+0x3c0>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	474080e7          	jalr	1140(ra) # 80000544 <panic>

00000000800060d8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060d8:	7159                	addi	sp,sp,-112
    800060da:	f486                	sd	ra,104(sp)
    800060dc:	f0a2                	sd	s0,96(sp)
    800060de:	eca6                	sd	s1,88(sp)
    800060e0:	e8ca                	sd	s2,80(sp)
    800060e2:	e4ce                	sd	s3,72(sp)
    800060e4:	e0d2                	sd	s4,64(sp)
    800060e6:	fc56                	sd	s5,56(sp)
    800060e8:	f85a                	sd	s6,48(sp)
    800060ea:	f45e                	sd	s7,40(sp)
    800060ec:	f062                	sd	s8,32(sp)
    800060ee:	ec66                	sd	s9,24(sp)
    800060f0:	e86a                	sd	s10,16(sp)
    800060f2:	1880                	addi	s0,sp,112
    800060f4:	892a                	mv	s2,a0
    800060f6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060f8:	00c52c83          	lw	s9,12(a0)
    800060fc:	001c9c9b          	slliw	s9,s9,0x1
    80006100:	1c82                	slli	s9,s9,0x20
    80006102:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006106:	0001c517          	auipc	a0,0x1c
    8000610a:	c0250513          	addi	a0,a0,-1022 # 80021d08 <disk+0x128>
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	adc080e7          	jalr	-1316(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006116:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006118:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000611a:	0001cb17          	auipc	s6,0x1c
    8000611e:	ac6b0b13          	addi	s6,s6,-1338 # 80021be0 <disk>
  for(int i = 0; i < 3; i++){
    80006122:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006124:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006126:	0001cc17          	auipc	s8,0x1c
    8000612a:	be2c0c13          	addi	s8,s8,-1054 # 80021d08 <disk+0x128>
    8000612e:	a8b5                	j	800061aa <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006130:	00fb06b3          	add	a3,s6,a5
    80006134:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006138:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000613a:	0207c563          	bltz	a5,80006164 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000613e:	2485                	addiw	s1,s1,1
    80006140:	0711                	addi	a4,a4,4
    80006142:	1f548a63          	beq	s1,s5,80006336 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006146:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006148:	0001c697          	auipc	a3,0x1c
    8000614c:	a9868693          	addi	a3,a3,-1384 # 80021be0 <disk>
    80006150:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006152:	0186c583          	lbu	a1,24(a3)
    80006156:	fde9                	bnez	a1,80006130 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006158:	2785                	addiw	a5,a5,1
    8000615a:	0685                	addi	a3,a3,1
    8000615c:	ff779be3          	bne	a5,s7,80006152 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006160:	57fd                	li	a5,-1
    80006162:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006164:	02905a63          	blez	s1,80006198 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006168:	f9042503          	lw	a0,-112(s0)
    8000616c:	00000097          	auipc	ra,0x0
    80006170:	cfa080e7          	jalr	-774(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    80006174:	4785                	li	a5,1
    80006176:	0297d163          	bge	a5,s1,80006198 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000617a:	f9442503          	lw	a0,-108(s0)
    8000617e:	00000097          	auipc	ra,0x0
    80006182:	ce8080e7          	jalr	-792(ra) # 80005e66 <free_desc>
      for(int j = 0; j < i; j++)
    80006186:	4789                	li	a5,2
    80006188:	0097d863          	bge	a5,s1,80006198 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000618c:	f9842503          	lw	a0,-104(s0)
    80006190:	00000097          	auipc	ra,0x0
    80006194:	cd6080e7          	jalr	-810(ra) # 80005e66 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006198:	85e2                	mv	a1,s8
    8000619a:	0001c517          	auipc	a0,0x1c
    8000619e:	a5e50513          	addi	a0,a0,-1442 # 80021bf8 <disk+0x18>
    800061a2:	ffffc097          	auipc	ra,0xffffc
    800061a6:	082080e7          	jalr	130(ra) # 80002224 <sleep>
  for(int i = 0; i < 3; i++){
    800061aa:	f9040713          	addi	a4,s0,-112
    800061ae:	84ce                	mv	s1,s3
    800061b0:	bf59                	j	80006146 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061b2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800061b6:	00479693          	slli	a3,a5,0x4
    800061ba:	0001c797          	auipc	a5,0x1c
    800061be:	a2678793          	addi	a5,a5,-1498 # 80021be0 <disk>
    800061c2:	97b6                	add	a5,a5,a3
    800061c4:	4685                	li	a3,1
    800061c6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800061c8:	0001c597          	auipc	a1,0x1c
    800061cc:	a1858593          	addi	a1,a1,-1512 # 80021be0 <disk>
    800061d0:	00a60793          	addi	a5,a2,10
    800061d4:	0792                	slli	a5,a5,0x4
    800061d6:	97ae                	add	a5,a5,a1
    800061d8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800061dc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800061e0:	f6070693          	addi	a3,a4,-160
    800061e4:	619c                	ld	a5,0(a1)
    800061e6:	97b6                	add	a5,a5,a3
    800061e8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061ea:	6188                	ld	a0,0(a1)
    800061ec:	96aa                	add	a3,a3,a0
    800061ee:	47c1                	li	a5,16
    800061f0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061f2:	4785                	li	a5,1
    800061f4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800061f8:	f9442783          	lw	a5,-108(s0)
    800061fc:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006200:	0792                	slli	a5,a5,0x4
    80006202:	953e                	add	a0,a0,a5
    80006204:	05890693          	addi	a3,s2,88
    80006208:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000620a:	6188                	ld	a0,0(a1)
    8000620c:	97aa                	add	a5,a5,a0
    8000620e:	40000693          	li	a3,1024
    80006212:	c794                	sw	a3,8(a5)
  if(write)
    80006214:	100d0d63          	beqz	s10,8000632e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006218:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000621c:	00c7d683          	lhu	a3,12(a5)
    80006220:	0016e693          	ori	a3,a3,1
    80006224:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006228:	f9842583          	lw	a1,-104(s0)
    8000622c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006230:	0001c697          	auipc	a3,0x1c
    80006234:	9b068693          	addi	a3,a3,-1616 # 80021be0 <disk>
    80006238:	00260793          	addi	a5,a2,2
    8000623c:	0792                	slli	a5,a5,0x4
    8000623e:	97b6                	add	a5,a5,a3
    80006240:	587d                	li	a6,-1
    80006242:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006246:	0592                	slli	a1,a1,0x4
    80006248:	952e                	add	a0,a0,a1
    8000624a:	f9070713          	addi	a4,a4,-112
    8000624e:	9736                	add	a4,a4,a3
    80006250:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006252:	6298                	ld	a4,0(a3)
    80006254:	972e                	add	a4,a4,a1
    80006256:	4585                	li	a1,1
    80006258:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000625a:	4509                	li	a0,2
    8000625c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006260:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006264:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006268:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000626c:	6698                	ld	a4,8(a3)
    8000626e:	00275783          	lhu	a5,2(a4)
    80006272:	8b9d                	andi	a5,a5,7
    80006274:	0786                	slli	a5,a5,0x1
    80006276:	97ba                	add	a5,a5,a4
    80006278:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000627c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006280:	6698                	ld	a4,8(a3)
    80006282:	00275783          	lhu	a5,2(a4)
    80006286:	2785                	addiw	a5,a5,1
    80006288:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000628c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006290:	100017b7          	lui	a5,0x10001
    80006294:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006298:	00492703          	lw	a4,4(s2)
    8000629c:	4785                	li	a5,1
    8000629e:	02f71163          	bne	a4,a5,800062c0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800062a2:	0001c997          	auipc	s3,0x1c
    800062a6:	a6698993          	addi	s3,s3,-1434 # 80021d08 <disk+0x128>
  while(b->disk == 1) {
    800062aa:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062ac:	85ce                	mv	a1,s3
    800062ae:	854a                	mv	a0,s2
    800062b0:	ffffc097          	auipc	ra,0xffffc
    800062b4:	f74080e7          	jalr	-140(ra) # 80002224 <sleep>
  while(b->disk == 1) {
    800062b8:	00492783          	lw	a5,4(s2)
    800062bc:	fe9788e3          	beq	a5,s1,800062ac <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800062c0:	f9042903          	lw	s2,-112(s0)
    800062c4:	00290793          	addi	a5,s2,2
    800062c8:	00479713          	slli	a4,a5,0x4
    800062cc:	0001c797          	auipc	a5,0x1c
    800062d0:	91478793          	addi	a5,a5,-1772 # 80021be0 <disk>
    800062d4:	97ba                	add	a5,a5,a4
    800062d6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800062da:	0001c997          	auipc	s3,0x1c
    800062de:	90698993          	addi	s3,s3,-1786 # 80021be0 <disk>
    800062e2:	00491713          	slli	a4,s2,0x4
    800062e6:	0009b783          	ld	a5,0(s3)
    800062ea:	97ba                	add	a5,a5,a4
    800062ec:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062f0:	854a                	mv	a0,s2
    800062f2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062f6:	00000097          	auipc	ra,0x0
    800062fa:	b70080e7          	jalr	-1168(ra) # 80005e66 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062fe:	8885                	andi	s1,s1,1
    80006300:	f0ed                	bnez	s1,800062e2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006302:	0001c517          	auipc	a0,0x1c
    80006306:	a0650513          	addi	a0,a0,-1530 # 80021d08 <disk+0x128>
    8000630a:	ffffb097          	auipc	ra,0xffffb
    8000630e:	994080e7          	jalr	-1644(ra) # 80000c9e <release>
}
    80006312:	70a6                	ld	ra,104(sp)
    80006314:	7406                	ld	s0,96(sp)
    80006316:	64e6                	ld	s1,88(sp)
    80006318:	6946                	ld	s2,80(sp)
    8000631a:	69a6                	ld	s3,72(sp)
    8000631c:	6a06                	ld	s4,64(sp)
    8000631e:	7ae2                	ld	s5,56(sp)
    80006320:	7b42                	ld	s6,48(sp)
    80006322:	7ba2                	ld	s7,40(sp)
    80006324:	7c02                	ld	s8,32(sp)
    80006326:	6ce2                	ld	s9,24(sp)
    80006328:	6d42                	ld	s10,16(sp)
    8000632a:	6165                	addi	sp,sp,112
    8000632c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000632e:	4689                	li	a3,2
    80006330:	00d79623          	sh	a3,12(a5)
    80006334:	b5e5                	j	8000621c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006336:	f9042603          	lw	a2,-112(s0)
    8000633a:	00a60713          	addi	a4,a2,10
    8000633e:	0712                	slli	a4,a4,0x4
    80006340:	0001c517          	auipc	a0,0x1c
    80006344:	8a850513          	addi	a0,a0,-1880 # 80021be8 <disk+0x8>
    80006348:	953a                	add	a0,a0,a4
  if(write)
    8000634a:	e60d14e3          	bnez	s10,800061b2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000634e:	00a60793          	addi	a5,a2,10
    80006352:	00479693          	slli	a3,a5,0x4
    80006356:	0001c797          	auipc	a5,0x1c
    8000635a:	88a78793          	addi	a5,a5,-1910 # 80021be0 <disk>
    8000635e:	97b6                	add	a5,a5,a3
    80006360:	0007a423          	sw	zero,8(a5)
    80006364:	b595                	j	800061c8 <virtio_disk_rw+0xf0>

0000000080006366 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006366:	1101                	addi	sp,sp,-32
    80006368:	ec06                	sd	ra,24(sp)
    8000636a:	e822                	sd	s0,16(sp)
    8000636c:	e426                	sd	s1,8(sp)
    8000636e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006370:	0001c497          	auipc	s1,0x1c
    80006374:	87048493          	addi	s1,s1,-1936 # 80021be0 <disk>
    80006378:	0001c517          	auipc	a0,0x1c
    8000637c:	99050513          	addi	a0,a0,-1648 # 80021d08 <disk+0x128>
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	86a080e7          	jalr	-1942(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006388:	10001737          	lui	a4,0x10001
    8000638c:	533c                	lw	a5,96(a4)
    8000638e:	8b8d                	andi	a5,a5,3
    80006390:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006392:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006396:	689c                	ld	a5,16(s1)
    80006398:	0204d703          	lhu	a4,32(s1)
    8000639c:	0027d783          	lhu	a5,2(a5)
    800063a0:	04f70863          	beq	a4,a5,800063f0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063a4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063a8:	6898                	ld	a4,16(s1)
    800063aa:	0204d783          	lhu	a5,32(s1)
    800063ae:	8b9d                	andi	a5,a5,7
    800063b0:	078e                	slli	a5,a5,0x3
    800063b2:	97ba                	add	a5,a5,a4
    800063b4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063b6:	00278713          	addi	a4,a5,2
    800063ba:	0712                	slli	a4,a4,0x4
    800063bc:	9726                	add	a4,a4,s1
    800063be:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063c2:	e721                	bnez	a4,8000640a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063c4:	0789                	addi	a5,a5,2
    800063c6:	0792                	slli	a5,a5,0x4
    800063c8:	97a6                	add	a5,a5,s1
    800063ca:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063cc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063d0:	ffffc097          	auipc	ra,0xffffc
    800063d4:	eb8080e7          	jalr	-328(ra) # 80002288 <wakeup>

    disk.used_idx += 1;
    800063d8:	0204d783          	lhu	a5,32(s1)
    800063dc:	2785                	addiw	a5,a5,1
    800063de:	17c2                	slli	a5,a5,0x30
    800063e0:	93c1                	srli	a5,a5,0x30
    800063e2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063e6:	6898                	ld	a4,16(s1)
    800063e8:	00275703          	lhu	a4,2(a4)
    800063ec:	faf71ce3          	bne	a4,a5,800063a4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063f0:	0001c517          	auipc	a0,0x1c
    800063f4:	91850513          	addi	a0,a0,-1768 # 80021d08 <disk+0x128>
    800063f8:	ffffb097          	auipc	ra,0xffffb
    800063fc:	8a6080e7          	jalr	-1882(ra) # 80000c9e <release>
}
    80006400:	60e2                	ld	ra,24(sp)
    80006402:	6442                	ld	s0,16(sp)
    80006404:	64a2                	ld	s1,8(sp)
    80006406:	6105                	addi	sp,sp,32
    80006408:	8082                	ret
      panic("virtio_disk_intr status");
    8000640a:	00002517          	auipc	a0,0x2
    8000640e:	3d650513          	addi	a0,a0,982 # 800087e0 <syscalls+0x3d8>
    80006412:	ffffa097          	auipc	ra,0xffffa
    80006416:	132080e7          	jalr	306(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
