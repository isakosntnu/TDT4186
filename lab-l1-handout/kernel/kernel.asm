
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	bce78793          	addi	a5,a5,-1074 # 80005c30 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdca7f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	388080e7          	jalr	904(ra) # 800024b2 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	134080e7          	jalr	308(ra) # 800022fc <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	24a080e7          	jalr	586(ra) # 8000245c <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

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
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f6:	216080e7          	jalr	534(ra) # 80002508 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
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
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00020797          	auipc	a5,0x20
    8000047c:	77078793          	addi	a5,a5,1904 # 80020be8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
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
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
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
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	824080e7          	jalr	-2012(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	736080e7          	jalr	1846(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	38478793          	addi	a5,a5,900 # 80021d80 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	2b250513          	addi	a0,a0,690 # 80021d80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd281>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	7fa080e7          	jalr	2042(ra) # 800026b8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	daa080e7          	jalr	-598(ra) # 80005c70 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	75a080e7          	jalr	1882(ra) # 80002690 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	77a080e7          	jalr	1914(ra) # 800026b8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	d14080e7          	jalr	-748(ra) # 80005c5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	d22080e7          	jalr	-734(ra) # 80005c70 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	eb8080e7          	jalr	-328(ra) # 80002e0e <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	558080e7          	jalr	1368(ra) # 800034b6 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	4fe080e7          	jalr	1278(ra) # 80004464 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	e0a080e7          	jalr	-502(ra) # 80005d78 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd277>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd280>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	75448493          	addi	s1,s1,1876 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	13aa0a13          	addi	s4,s4,314 # 800169a0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	16848493          	addi	s1,s1,360
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	69048493          	addi	s1,s1,1680 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00015997          	auipc	s3,0x15
    80001936:	06e98993          	addi	s3,s3,110 # 800169a0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	16848493          	addi	s1,s1,360
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	cca080e7          	jalr	-822(ra) # 800026d0 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	a16080e7          	jalr	-1514(ra) # 80003436 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3de48493          	addi	s1,s1,990 # 80010fa0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	dd690913          	addi	s2,s2,-554 # 800169a0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	16848493          	addi	s1,s1,360
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c6a7b023          	sd	a0,-928(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bcc58593          	addi	a1,a1,-1076 # 80008870 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	17e080e7          	jalr	382(ra) # 80003e60 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  else if (n < 0)
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if (p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	6e4080e7          	jalr	1764(ra) # 800044f6 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	852080e7          	jalr	-1966(ra) # 80003676 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d3848493          	addi	s1,s1,-712 # 80010b88 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	cb270713          	addi	a4,a4,-846 # 80010b70 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	cdc70713          	addi	a4,a4,-804 # 80010ba8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	c94a0a13          	addi	s4,s4,-876 # 80010b70 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	aba90913          	addi	s2,s2,-1350 # 800169a0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0a648493          	addi	s1,s1,166 # 80010fa0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f0e:	16848493          	addi	s1,s1,360
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if (p->state == RUNNABLE)
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00000097          	auipc	ra,0x0
    80001f38:	6f2080e7          	jalr	1778(ra) # 80002626 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c0670713          	addi	a4,a4,-1018 # 80010b70 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if (p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	be090913          	addi	s2,s2,-1056 # 80010b70 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c0058593          	addi	a1,a1,-1024 # 80010ba8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	670080e7          	jalr	1648(ra) # 80002626 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	993e                	add	s2,s2,a5
    80001fc6:	0b392623          	sw	s3,172(s2)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	560080e7          	jalr	1376(ra) # 80000540 <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	530080e7          	jalr	1328(ra) # 80000540 <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	ed448493          	addi	s1,s1,-300 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800020d4:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	8c890913          	addi	s2,s2,-1848 # 800169a0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800020ec:	16848493          	addi	s1,s1,360
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if (p != myproc())
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <reparent>:
{
    8000212e:	7179                	addi	sp,sp,-48
    80002130:	f406                	sd	ra,40(sp)
    80002132:	f022                	sd	s0,32(sp)
    80002134:	ec26                	sd	s1,24(sp)
    80002136:	e84a                	sd	s2,16(sp)
    80002138:	e44e                	sd	s3,8(sp)
    8000213a:	e052                	sd	s4,0(sp)
    8000213c:	1800                	addi	s0,sp,48
    8000213e:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002140:	0000f497          	auipc	s1,0xf
    80002144:	e6048493          	addi	s1,s1,-416 # 80010fa0 <proc>
      pp->parent = initproc;
    80002148:	00006a17          	auipc	s4,0x6
    8000214c:	7b0a0a13          	addi	s4,s4,1968 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002150:	00015997          	auipc	s3,0x15
    80002154:	85098993          	addi	s3,s3,-1968 # 800169a0 <tickslock>
    80002158:	a029                	j	80002162 <reparent+0x34>
    8000215a:	16848493          	addi	s1,s1,360
    8000215e:	01348d63          	beq	s1,s3,80002178 <reparent+0x4a>
    if (pp->parent == p)
    80002162:	7c9c                	ld	a5,56(s1)
    80002164:	ff279be3          	bne	a5,s2,8000215a <reparent+0x2c>
      pp->parent = initproc;
    80002168:	000a3503          	ld	a0,0(s4)
    8000216c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	f4a080e7          	jalr	-182(ra) # 800020b8 <wakeup>
    80002176:	b7d5                	j	8000215a <reparent+0x2c>
}
    80002178:	70a2                	ld	ra,40(sp)
    8000217a:	7402                	ld	s0,32(sp)
    8000217c:	64e2                	ld	s1,24(sp)
    8000217e:	6942                	ld	s2,16(sp)
    80002180:	69a2                	ld	s3,8(sp)
    80002182:	6a02                	ld	s4,0(sp)
    80002184:	6145                	addi	sp,sp,48
    80002186:	8082                	ret

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	812080e7          	jalr	-2030(ra) # 800019ac <myproc>
    800021a2:	89aa                	mv	s3,a0
  if (p == initproc)
    800021a4:	00006797          	auipc	a5,0x6
    800021a8:	7547b783          	ld	a5,1876(a5) # 800088f8 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	0a850513          	addi	a0,a0,168 # 80008260 <digits+0x220>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	380080e7          	jalr	896(ra) # 80004548 <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if (p->ofile[fd])
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	ea0080e7          	jalr	-352(ra) # 80004080 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	682080e7          	jalr	1666(ra) # 8000386e <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	f0a080e7          	jalr	-246(ra) # 800040fe <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	98848493          	addi	s1,s1,-1656 # 80010b88 <wait_lock>
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	9cc080e7          	jalr	-1588(ra) # 80000bd6 <acquire>
  reparent(p);
    80002212:	854e                	mv	a0,s3
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f1a080e7          	jalr	-230(ra) # 8000212e <reparent>
  wakeup(p->parent);
    8000221c:	0389b503          	ld	a0,56(s3)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	e98080e7          	jalr	-360(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    80002228:	854e                	mv	a0,s3
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9ac080e7          	jalr	-1620(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002232:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002236:	4795                	li	a5,5
    80002238:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000223c:	8526                	mv	a0,s1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	a4c080e7          	jalr	-1460(ra) # 80000c8a <release>
  sched();
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	cfc080e7          	jalr	-772(ra) # 80001f42 <sched>
  panic("zombie exit");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	02250513          	addi	a0,a0,34 # 80008270 <digits+0x230>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000225e:	7179                	addi	sp,sp,-48
    80002260:	f406                	sd	ra,40(sp)
    80002262:	f022                	sd	s0,32(sp)
    80002264:	ec26                	sd	s1,24(sp)
    80002266:	e84a                	sd	s2,16(sp)
    80002268:	e44e                	sd	s3,8(sp)
    8000226a:	1800                	addi	s0,sp,48
    8000226c:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000226e:	0000f497          	auipc	s1,0xf
    80002272:	d3248493          	addi	s1,s1,-718 # 80010fa0 <proc>
    80002276:	00014997          	auipc	s3,0x14
    8000227a:	72a98993          	addi	s3,s3,1834 # 800169a0 <tickslock>
  {
    acquire(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	956080e7          	jalr	-1706(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002288:	589c                	lw	a5,48(s1)
    8000228a:	01278d63          	beq	a5,s2,800022a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000228e:	8526                	mv	a0,s1
    80002290:	fffff097          	auipc	ra,0xfffff
    80002294:	9fa080e7          	jalr	-1542(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002298:	16848493          	addi	s1,s1,360
    8000229c:	ff3491e3          	bne	s1,s3,8000227e <kill+0x20>
  }
  return -1;
    800022a0:	557d                	li	a0,-1
    800022a2:	a829                	j	800022bc <kill+0x5e>
      p->killed = 1;
    800022a4:	4785                	li	a5,1
    800022a6:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800022a8:	4c98                	lw	a4,24(s1)
    800022aa:	4789                	li	a5,2
    800022ac:	00f70f63          	beq	a4,a5,800022ca <kill+0x6c>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
      return 0;
    800022ba:	4501                	li	a0,0
}
    800022bc:	70a2                	ld	ra,40(sp)
    800022be:	7402                	ld	s0,32(sp)
    800022c0:	64e2                	ld	s1,24(sp)
    800022c2:	6942                	ld	s2,16(sp)
    800022c4:	69a2                	ld	s3,8(sp)
    800022c6:	6145                	addi	sp,sp,48
    800022c8:	8082                	ret
        p->state = RUNNABLE;
    800022ca:	478d                	li	a5,3
    800022cc:	cc9c                	sw	a5,24(s1)
    800022ce:	b7cd                	j	800022b0 <kill+0x52>

00000000800022d0 <setkilled>:

void setkilled(struct proc *p)
{
    800022d0:	1101                	addi	sp,sp,-32
    800022d2:	ec06                	sd	ra,24(sp)
    800022d4:	e822                	sd	s0,16(sp)
    800022d6:	e426                	sd	s1,8(sp)
    800022d8:	1000                	addi	s0,sp,32
    800022da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	8fa080e7          	jalr	-1798(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800022e4:	4785                	li	a5,1
    800022e6:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022e8:	8526                	mv	a0,s1
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9a0080e7          	jalr	-1632(ra) # 80000c8a <release>
}
    800022f2:	60e2                	ld	ra,24(sp)
    800022f4:	6442                	ld	s0,16(sp)
    800022f6:	64a2                	ld	s1,8(sp)
    800022f8:	6105                	addi	sp,sp,32
    800022fa:	8082                	ret

00000000800022fc <killed>:

int killed(struct proc *p)
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	e04a                	sd	s2,0(sp)
    80002306:	1000                	addi	s0,sp,32
    80002308:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002312:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	972080e7          	jalr	-1678(ra) # 80000c8a <release>
  return k;
}
    80002320:	854a                	mv	a0,s2
    80002322:	60e2                	ld	ra,24(sp)
    80002324:	6442                	ld	s0,16(sp)
    80002326:	64a2                	ld	s1,8(sp)
    80002328:	6902                	ld	s2,0(sp)
    8000232a:	6105                	addi	sp,sp,32
    8000232c:	8082                	ret

000000008000232e <wait>:
{
    8000232e:	715d                	addi	sp,sp,-80
    80002330:	e486                	sd	ra,72(sp)
    80002332:	e0a2                	sd	s0,64(sp)
    80002334:	fc26                	sd	s1,56(sp)
    80002336:	f84a                	sd	s2,48(sp)
    80002338:	f44e                	sd	s3,40(sp)
    8000233a:	f052                	sd	s4,32(sp)
    8000233c:	ec56                	sd	s5,24(sp)
    8000233e:	e85a                	sd	s6,16(sp)
    80002340:	e45e                	sd	s7,8(sp)
    80002342:	e062                	sd	s8,0(sp)
    80002344:	0880                	addi	s0,sp,80
    80002346:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	664080e7          	jalr	1636(ra) # 800019ac <myproc>
    80002350:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002352:	0000f517          	auipc	a0,0xf
    80002356:	83650513          	addi	a0,a0,-1994 # 80010b88 <wait_lock>
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002362:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002364:	4a15                	li	s4,5
        havekids = 1;
    80002366:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002368:	00014997          	auipc	s3,0x14
    8000236c:	63898993          	addi	s3,s3,1592 # 800169a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002370:	0000fc17          	auipc	s8,0xf
    80002374:	818c0c13          	addi	s8,s8,-2024 # 80010b88 <wait_lock>
    havekids = 0;
    80002378:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000237a:	0000f497          	auipc	s1,0xf
    8000237e:	c2648493          	addi	s1,s1,-986 # 80010fa0 <proc>
    80002382:	a0bd                	j	800023f0 <wait+0xc2>
          pid = pp->pid;
    80002384:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002388:	000b0e63          	beqz	s6,800023a4 <wait+0x76>
    8000238c:	4691                	li	a3,4
    8000238e:	02c48613          	addi	a2,s1,44
    80002392:	85da                	mv	a1,s6
    80002394:	05093503          	ld	a0,80(s2)
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	2d4080e7          	jalr	724(ra) # 8000166c <copyout>
    800023a0:	02054563          	bltz	a0,800023ca <wait+0x9c>
          freeproc(pp);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	7b8080e7          	jalr	1976(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8da080e7          	jalr	-1830(ra) # 80000c8a <release>
          release(&wait_lock);
    800023b8:	0000e517          	auipc	a0,0xe
    800023bc:	7d050513          	addi	a0,a0,2000 # 80010b88 <wait_lock>
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8ca080e7          	jalr	-1846(ra) # 80000c8a <release>
          return pid;
    800023c8:	a0b5                	j	80002434 <wait+0x106>
            release(&pp->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8be080e7          	jalr	-1858(ra) # 80000c8a <release>
            release(&wait_lock);
    800023d4:	0000e517          	auipc	a0,0xe
    800023d8:	7b450513          	addi	a0,a0,1972 # 80010b88 <wait_lock>
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
            return -1;
    800023e4:	59fd                	li	s3,-1
    800023e6:	a0b9                	j	80002434 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800023e8:	16848493          	addi	s1,s1,360
    800023ec:	03348463          	beq	s1,s3,80002414 <wait+0xe6>
      if (pp->parent == p)
    800023f0:	7c9c                	ld	a5,56(s1)
    800023f2:	ff279be3          	bne	a5,s2,800023e8 <wait+0xba>
        acquire(&pp->lock);
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7de080e7          	jalr	2014(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002400:	4c9c                	lw	a5,24(s1)
    80002402:	f94781e3          	beq	a5,s4,80002384 <wait+0x56>
        release(&pp->lock);
    80002406:	8526                	mv	a0,s1
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	882080e7          	jalr	-1918(ra) # 80000c8a <release>
        havekids = 1;
    80002410:	8756                	mv	a4,s5
    80002412:	bfd9                	j	800023e8 <wait+0xba>
    if (!havekids || killed(p))
    80002414:	c719                	beqz	a4,80002422 <wait+0xf4>
    80002416:	854a                	mv	a0,s2
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	ee4080e7          	jalr	-284(ra) # 800022fc <killed>
    80002420:	c51d                	beqz	a0,8000244e <wait+0x120>
      release(&wait_lock);
    80002422:	0000e517          	auipc	a0,0xe
    80002426:	76650513          	addi	a0,a0,1894 # 80010b88 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	860080e7          	jalr	-1952(ra) # 80000c8a <release>
      return -1;
    80002432:	59fd                	li	s3,-1
}
    80002434:	854e                	mv	a0,s3
    80002436:	60a6                	ld	ra,72(sp)
    80002438:	6406                	ld	s0,64(sp)
    8000243a:	74e2                	ld	s1,56(sp)
    8000243c:	7942                	ld	s2,48(sp)
    8000243e:	79a2                	ld	s3,40(sp)
    80002440:	7a02                	ld	s4,32(sp)
    80002442:	6ae2                	ld	s5,24(sp)
    80002444:	6b42                	ld	s6,16(sp)
    80002446:	6ba2                	ld	s7,8(sp)
    80002448:	6c02                	ld	s8,0(sp)
    8000244a:	6161                	addi	sp,sp,80
    8000244c:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000244e:	85e2                	mv	a1,s8
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	c02080e7          	jalr	-1022(ra) # 80002054 <sleep>
    havekids = 0;
    8000245a:	bf39                	j	80002378 <wait+0x4a>

000000008000245c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000245c:	7179                	addi	sp,sp,-48
    8000245e:	f406                	sd	ra,40(sp)
    80002460:	f022                	sd	s0,32(sp)
    80002462:	ec26                	sd	s1,24(sp)
    80002464:	e84a                	sd	s2,16(sp)
    80002466:	e44e                	sd	s3,8(sp)
    80002468:	e052                	sd	s4,0(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	84aa                	mv	s1,a0
    8000246e:	892e                	mv	s2,a1
    80002470:	89b2                	mv	s3,a2
    80002472:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
  if (user_dst)
    8000247c:	c08d                	beqz	s1,8000249e <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000247e:	86d2                	mv	a3,s4
    80002480:	864e                	mv	a2,s3
    80002482:	85ca                	mv	a1,s2
    80002484:	6928                	ld	a0,80(a0)
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	1e6080e7          	jalr	486(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000248e:	70a2                	ld	ra,40(sp)
    80002490:	7402                	ld	s0,32(sp)
    80002492:	64e2                	ld	s1,24(sp)
    80002494:	6942                	ld	s2,16(sp)
    80002496:	69a2                	ld	s3,8(sp)
    80002498:	6a02                	ld	s4,0(sp)
    8000249a:	6145                	addi	sp,sp,48
    8000249c:	8082                	ret
    memmove((char *)dst, src, len);
    8000249e:	000a061b          	sext.w	a2,s4
    800024a2:	85ce                	mv	a1,s3
    800024a4:	854a                	mv	a0,s2
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	888080e7          	jalr	-1912(ra) # 80000d2e <memmove>
    return 0;
    800024ae:	8526                	mv	a0,s1
    800024b0:	bff9                	j	8000248e <either_copyout+0x32>

00000000800024b2 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024b2:	7179                	addi	sp,sp,-48
    800024b4:	f406                	sd	ra,40(sp)
    800024b6:	f022                	sd	s0,32(sp)
    800024b8:	ec26                	sd	s1,24(sp)
    800024ba:	e84a                	sd	s2,16(sp)
    800024bc:	e44e                	sd	s3,8(sp)
    800024be:	e052                	sd	s4,0(sp)
    800024c0:	1800                	addi	s0,sp,48
    800024c2:	892a                	mv	s2,a0
    800024c4:	84ae                	mv	s1,a1
    800024c6:	89b2                	mv	s3,a2
    800024c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	4e2080e7          	jalr	1250(ra) # 800019ac <myproc>
  if (user_src)
    800024d2:	c08d                	beqz	s1,800024f4 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800024d4:	86d2                	mv	a3,s4
    800024d6:	864e                	mv	a2,s3
    800024d8:	85ca                	mv	a1,s2
    800024da:	6928                	ld	a0,80(a0)
    800024dc:	fffff097          	auipc	ra,0xfffff
    800024e0:	21c080e7          	jalr	540(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800024e4:	70a2                	ld	ra,40(sp)
    800024e6:	7402                	ld	s0,32(sp)
    800024e8:	64e2                	ld	s1,24(sp)
    800024ea:	6942                	ld	s2,16(sp)
    800024ec:	69a2                	ld	s3,8(sp)
    800024ee:	6a02                	ld	s4,0(sp)
    800024f0:	6145                	addi	sp,sp,48
    800024f2:	8082                	ret
    memmove(dst, (char *)src, len);
    800024f4:	000a061b          	sext.w	a2,s4
    800024f8:	85ce                	mv	a1,s3
    800024fa:	854a                	mv	a0,s2
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	832080e7          	jalr	-1998(ra) # 80000d2e <memmove>
    return 0;
    80002504:	8526                	mv	a0,s1
    80002506:	bff9                	j	800024e4 <either_copyin+0x32>

0000000080002508 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002508:	715d                	addi	sp,sp,-80
    8000250a:	e486                	sd	ra,72(sp)
    8000250c:	e0a2                	sd	s0,64(sp)
    8000250e:	fc26                	sd	s1,56(sp)
    80002510:	f84a                	sd	s2,48(sp)
    80002512:	f44e                	sd	s3,40(sp)
    80002514:	f052                	sd	s4,32(sp)
    80002516:	ec56                	sd	s5,24(sp)
    80002518:	e85a                	sd	s6,16(sp)
    8000251a:	e45e                	sd	s7,8(sp)
    8000251c:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	baa50513          	addi	a0,a0,-1110 # 800080c8 <digits+0x88>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	064080e7          	jalr	100(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000252e:	0000f497          	auipc	s1,0xf
    80002532:	bca48493          	addi	s1,s1,-1078 # 800110f8 <proc+0x158>
    80002536:	00014917          	auipc	s2,0x14
    8000253a:	5c290913          	addi	s2,s2,1474 # 80016af8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000253e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002540:	00006997          	auipc	s3,0x6
    80002544:	d4098993          	addi	s3,s3,-704 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002548:	00006a97          	auipc	s5,0x6
    8000254c:	d40a8a93          	addi	s5,s5,-704 # 80008288 <digits+0x248>
    printf("\n");
    80002550:	00006a17          	auipc	s4,0x6
    80002554:	b78a0a13          	addi	s4,s4,-1160 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002558:	00006b97          	auipc	s7,0x6
    8000255c:	d88b8b93          	addi	s7,s7,-632 # 800082e0 <states.0>
    80002560:	a00d                	j	80002582 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002562:	ed86a583          	lw	a1,-296(a3)
    80002566:	8556                	mv	a0,s5
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	022080e7          	jalr	34(ra) # 8000058a <printf>
    printf("\n");
    80002570:	8552                	mv	a0,s4
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	018080e7          	jalr	24(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000257a:	16848493          	addi	s1,s1,360
    8000257e:	03248263          	beq	s1,s2,800025a2 <procdump+0x9a>
    if (p->state == UNUSED)
    80002582:	86a6                	mv	a3,s1
    80002584:	ec04a783          	lw	a5,-320(s1)
    80002588:	dbed                	beqz	a5,8000257a <procdump+0x72>
      state = "???";
    8000258a:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	fcfb6be3          	bltu	s6,a5,80002562 <procdump+0x5a>
    80002590:	02079713          	slli	a4,a5,0x20
    80002594:	01d75793          	srli	a5,a4,0x1d
    80002598:	97de                	add	a5,a5,s7
    8000259a:	6390                	ld	a2,0(a5)
    8000259c:	f279                	bnez	a2,80002562 <procdump+0x5a>
      state = "???";
    8000259e:	864e                	mv	a2,s3
    800025a0:	b7c9                	j	80002562 <procdump+0x5a>
  }
}
    800025a2:	60a6                	ld	ra,72(sp)
    800025a4:	6406                	ld	s0,64(sp)
    800025a6:	74e2                	ld	s1,56(sp)
    800025a8:	7942                	ld	s2,48(sp)
    800025aa:	79a2                	ld	s3,40(sp)
    800025ac:	7a02                	ld	s4,32(sp)
    800025ae:	6ae2                	ld	s5,24(sp)
    800025b0:	6b42                	ld	s6,16(sp)
    800025b2:	6ba2                	ld	s7,8(sp)
    800025b4:	6161                	addi	sp,sp,80
    800025b6:	8082                	ret

00000000800025b8 <pss>:

void pss(void)
{
    800025b8:	7179                	addi	sp,sp,-48
    800025ba:	f406                	sd	ra,40(sp)
    800025bc:	f022                	sd	s0,32(sp)
    800025be:	ec26                	sd	s1,24(sp)
    800025c0:	e84a                	sd	s2,16(sp)
    800025c2:	e44e                	sd	s3,8(sp)
    800025c4:	e052                	sd	s4,0(sp)
    800025c6:	1800                	addi	s0,sp,48
}

};

  */
  proc->pid = 1;
    800025c8:	4785                	li	a5,1
    800025ca:	0000f717          	auipc	a4,0xf
    800025ce:	a0f72323          	sw	a5,-1530(a4) # 80010fd0 <proc+0x30>

  for (prossess = proc; prossess < &proc[NPROC];)
    800025d2:	0000f497          	auipc	s1,0xf
    800025d6:	c8e48493          	addi	s1,s1,-882 # 80011260 <proc+0x2c0>
    800025da:	00014917          	auipc	s2,0x14
    800025de:	68690913          	addi	s2,s2,1670 # 80016c60 <bcache+0x2a8>
  {

    prossess = prossess + 1;
    if (prossess->state == UNUSED)
      continue;
    printf("%s (%d): %d ", prossess->name, prossess->pid, prossess->state, "   \n");
    800025e2:	00006a17          	auipc	s4,0x6
    800025e6:	cb6a0a13          	addi	s4,s4,-842 # 80008298 <digits+0x258>
    800025ea:	00006997          	auipc	s3,0x6
    800025ee:	cb698993          	addi	s3,s3,-842 # 800082a0 <digits+0x260>
    800025f2:	a029                	j	800025fc <pss+0x44>
  for (prossess = proc; prossess < &proc[NPROC];)
    800025f4:	16848493          	addi	s1,s1,360
    800025f8:	01248f63          	beq	s1,s2,80002616 <pss+0x5e>
    if (prossess->state == UNUSED)
    800025fc:	ec04a683          	lw	a3,-320(s1)
    80002600:	daf5                	beqz	a3,800025f4 <pss+0x3c>
    printf("%s (%d): %d ", prossess->name, prossess->pid, prossess->state, "   \n");
    80002602:	8752                	mv	a4,s4
    80002604:	ed84a603          	lw	a2,-296(s1)
    80002608:	85a6                	mv	a1,s1
    8000260a:	854e                	mv	a0,s3
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	f7e080e7          	jalr	-130(ra) # 8000058a <printf>
    80002614:	b7c5                	j	800025f4 <pss+0x3c>
  }
}
    80002616:	70a2                	ld	ra,40(sp)
    80002618:	7402                	ld	s0,32(sp)
    8000261a:	64e2                	ld	s1,24(sp)
    8000261c:	6942                	ld	s2,16(sp)
    8000261e:	69a2                	ld	s3,8(sp)
    80002620:	6a02                	ld	s4,0(sp)
    80002622:	6145                	addi	sp,sp,48
    80002624:	8082                	ret

0000000080002626 <swtch>:
    80002626:	00153023          	sd	ra,0(a0)
    8000262a:	00253423          	sd	sp,8(a0)
    8000262e:	e900                	sd	s0,16(a0)
    80002630:	ed04                	sd	s1,24(a0)
    80002632:	03253023          	sd	s2,32(a0)
    80002636:	03353423          	sd	s3,40(a0)
    8000263a:	03453823          	sd	s4,48(a0)
    8000263e:	03553c23          	sd	s5,56(a0)
    80002642:	05653023          	sd	s6,64(a0)
    80002646:	05753423          	sd	s7,72(a0)
    8000264a:	05853823          	sd	s8,80(a0)
    8000264e:	05953c23          	sd	s9,88(a0)
    80002652:	07a53023          	sd	s10,96(a0)
    80002656:	07b53423          	sd	s11,104(a0)
    8000265a:	0005b083          	ld	ra,0(a1)
    8000265e:	0085b103          	ld	sp,8(a1)
    80002662:	6980                	ld	s0,16(a1)
    80002664:	6d84                	ld	s1,24(a1)
    80002666:	0205b903          	ld	s2,32(a1)
    8000266a:	0285b983          	ld	s3,40(a1)
    8000266e:	0305ba03          	ld	s4,48(a1)
    80002672:	0385ba83          	ld	s5,56(a1)
    80002676:	0405bb03          	ld	s6,64(a1)
    8000267a:	0485bb83          	ld	s7,72(a1)
    8000267e:	0505bc03          	ld	s8,80(a1)
    80002682:	0585bc83          	ld	s9,88(a1)
    80002686:	0605bd03          	ld	s10,96(a1)
    8000268a:	0685bd83          	ld	s11,104(a1)
    8000268e:	8082                	ret

0000000080002690 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002690:	1141                	addi	sp,sp,-16
    80002692:	e406                	sd	ra,8(sp)
    80002694:	e022                	sd	s0,0(sp)
    80002696:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002698:	00006597          	auipc	a1,0x6
    8000269c:	c7858593          	addi	a1,a1,-904 # 80008310 <states.0+0x30>
    800026a0:	00014517          	auipc	a0,0x14
    800026a4:	30050513          	addi	a0,a0,768 # 800169a0 <tickslock>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	49e080e7          	jalr	1182(ra) # 80000b46 <initlock>
}
    800026b0:	60a2                	ld	ra,8(sp)
    800026b2:	6402                	ld	s0,0(sp)
    800026b4:	0141                	addi	sp,sp,16
    800026b6:	8082                	ret

00000000800026b8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026b8:	1141                	addi	sp,sp,-16
    800026ba:	e422                	sd	s0,8(sp)
    800026bc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026be:	00003797          	auipc	a5,0x3
    800026c2:	4e278793          	addi	a5,a5,1250 # 80005ba0 <kernelvec>
    800026c6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ca:	6422                	ld	s0,8(sp)
    800026cc:	0141                	addi	sp,sp,16
    800026ce:	8082                	ret

00000000800026d0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026d0:	1141                	addi	sp,sp,-16
    800026d2:	e406                	sd	ra,8(sp)
    800026d4:	e022                	sd	s0,0(sp)
    800026d6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026d8:	fffff097          	auipc	ra,0xfffff
    800026dc:	2d4080e7          	jalr	724(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026e4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026ea:	00005697          	auipc	a3,0x5
    800026ee:	91668693          	addi	a3,a3,-1770 # 80007000 <_trampoline>
    800026f2:	00005717          	auipc	a4,0x5
    800026f6:	90e70713          	addi	a4,a4,-1778 # 80007000 <_trampoline>
    800026fa:	8f15                	sub	a4,a4,a3
    800026fc:	040007b7          	lui	a5,0x4000
    80002700:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002702:	07b2                	slli	a5,a5,0xc
    80002704:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002706:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000270a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000270c:	18002673          	csrr	a2,satp
    80002710:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002712:	6d30                	ld	a2,88(a0)
    80002714:	6138                	ld	a4,64(a0)
    80002716:	6585                	lui	a1,0x1
    80002718:	972e                	add	a4,a4,a1
    8000271a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000271c:	6d38                	ld	a4,88(a0)
    8000271e:	00000617          	auipc	a2,0x0
    80002722:	13060613          	addi	a2,a2,304 # 8000284e <usertrap>
    80002726:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002728:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000272a:	8612                	mv	a2,tp
    8000272c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002732:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002736:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000273a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000273e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002740:	6f18                	ld	a4,24(a4)
    80002742:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002746:	6928                	ld	a0,80(a0)
    80002748:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000274a:	00005717          	auipc	a4,0x5
    8000274e:	95270713          	addi	a4,a4,-1710 # 8000709c <userret>
    80002752:	8f15                	sub	a4,a4,a3
    80002754:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002756:	577d                	li	a4,-1
    80002758:	177e                	slli	a4,a4,0x3f
    8000275a:	8d59                	or	a0,a0,a4
    8000275c:	9782                	jalr	a5
}
    8000275e:	60a2                	ld	ra,8(sp)
    80002760:	6402                	ld	s0,0(sp)
    80002762:	0141                	addi	sp,sp,16
    80002764:	8082                	ret

0000000080002766 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002766:	1101                	addi	sp,sp,-32
    80002768:	ec06                	sd	ra,24(sp)
    8000276a:	e822                	sd	s0,16(sp)
    8000276c:	e426                	sd	s1,8(sp)
    8000276e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002770:	00014497          	auipc	s1,0x14
    80002774:	23048493          	addi	s1,s1,560 # 800169a0 <tickslock>
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	45c080e7          	jalr	1116(ra) # 80000bd6 <acquire>
  ticks++;
    80002782:	00006517          	auipc	a0,0x6
    80002786:	17e50513          	addi	a0,a0,382 # 80008900 <ticks>
    8000278a:	411c                	lw	a5,0(a0)
    8000278c:	2785                	addiw	a5,a5,1
    8000278e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002790:	00000097          	auipc	ra,0x0
    80002794:	928080e7          	jalr	-1752(ra) # 800020b8 <wakeup>
  release(&tickslock);
    80002798:	8526                	mv	a0,s1
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	4f0080e7          	jalr	1264(ra) # 80000c8a <release>
}
    800027a2:	60e2                	ld	ra,24(sp)
    800027a4:	6442                	ld	s0,16(sp)
    800027a6:	64a2                	ld	s1,8(sp)
    800027a8:	6105                	addi	sp,sp,32
    800027aa:	8082                	ret

00000000800027ac <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ac:	1101                	addi	sp,sp,-32
    800027ae:	ec06                	sd	ra,24(sp)
    800027b0:	e822                	sd	s0,16(sp)
    800027b2:	e426                	sd	s1,8(sp)
    800027b4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027b6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ba:	00074d63          	bltz	a4,800027d4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027be:	57fd                	li	a5,-1
    800027c0:	17fe                	slli	a5,a5,0x3f
    800027c2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027c4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027c6:	06f70363          	beq	a4,a5,8000282c <devintr+0x80>
  }
}
    800027ca:	60e2                	ld	ra,24(sp)
    800027cc:	6442                	ld	s0,16(sp)
    800027ce:	64a2                	ld	s1,8(sp)
    800027d0:	6105                	addi	sp,sp,32
    800027d2:	8082                	ret
     (scause & 0xff) == 9){
    800027d4:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027d8:	46a5                	li	a3,9
    800027da:	fed792e3          	bne	a5,a3,800027be <devintr+0x12>
    int irq = plic_claim();
    800027de:	00003097          	auipc	ra,0x3
    800027e2:	4ca080e7          	jalr	1226(ra) # 80005ca8 <plic_claim>
    800027e6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027e8:	47a9                	li	a5,10
    800027ea:	02f50763          	beq	a0,a5,80002818 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ee:	4785                	li	a5,1
    800027f0:	02f50963          	beq	a0,a5,80002822 <devintr+0x76>
    return 1;
    800027f4:	4505                	li	a0,1
    } else if(irq){
    800027f6:	d8f1                	beqz	s1,800027ca <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f8:	85a6                	mv	a1,s1
    800027fa:	00006517          	auipc	a0,0x6
    800027fe:	b1e50513          	addi	a0,a0,-1250 # 80008318 <states.0+0x38>
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	d88080e7          	jalr	-632(ra) # 8000058a <printf>
      plic_complete(irq);
    8000280a:	8526                	mv	a0,s1
    8000280c:	00003097          	auipc	ra,0x3
    80002810:	4c0080e7          	jalr	1216(ra) # 80005ccc <plic_complete>
    return 1;
    80002814:	4505                	li	a0,1
    80002816:	bf55                	j	800027ca <devintr+0x1e>
      uartintr();
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	180080e7          	jalr	384(ra) # 80000998 <uartintr>
    80002820:	b7ed                	j	8000280a <devintr+0x5e>
      virtio_disk_intr();
    80002822:	00004097          	auipc	ra,0x4
    80002826:	972080e7          	jalr	-1678(ra) # 80006194 <virtio_disk_intr>
    8000282a:	b7c5                	j	8000280a <devintr+0x5e>
    if(cpuid() == 0){
    8000282c:	fffff097          	auipc	ra,0xfffff
    80002830:	154080e7          	jalr	340(ra) # 80001980 <cpuid>
    80002834:	c901                	beqz	a0,80002844 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002836:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000283a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000283c:	14479073          	csrw	sip,a5
    return 2;
    80002840:	4509                	li	a0,2
    80002842:	b761                	j	800027ca <devintr+0x1e>
      clockintr();
    80002844:	00000097          	auipc	ra,0x0
    80002848:	f22080e7          	jalr	-222(ra) # 80002766 <clockintr>
    8000284c:	b7ed                	j	80002836 <devintr+0x8a>

000000008000284e <usertrap>:
{
    8000284e:	1101                	addi	sp,sp,-32
    80002850:	ec06                	sd	ra,24(sp)
    80002852:	e822                	sd	s0,16(sp)
    80002854:	e426                	sd	s1,8(sp)
    80002856:	e04a                	sd	s2,0(sp)
    80002858:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000285a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000285e:	1007f793          	andi	a5,a5,256
    80002862:	e3b1                	bnez	a5,800028a6 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002864:	00003797          	auipc	a5,0x3
    80002868:	33c78793          	addi	a5,a5,828 # 80005ba0 <kernelvec>
    8000286c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	13c080e7          	jalr	316(ra) # 800019ac <myproc>
    80002878:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000287a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000287c:	14102773          	csrr	a4,sepc
    80002880:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002882:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002886:	47a1                	li	a5,8
    80002888:	02f70763          	beq	a4,a5,800028b6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000288c:	00000097          	auipc	ra,0x0
    80002890:	f20080e7          	jalr	-224(ra) # 800027ac <devintr>
    80002894:	892a                	mv	s2,a0
    80002896:	c151                	beqz	a0,8000291a <usertrap+0xcc>
  if(killed(p))
    80002898:	8526                	mv	a0,s1
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	a62080e7          	jalr	-1438(ra) # 800022fc <killed>
    800028a2:	c929                	beqz	a0,800028f4 <usertrap+0xa6>
    800028a4:	a099                	j	800028ea <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028a6:	00006517          	auipc	a0,0x6
    800028aa:	a9250513          	addi	a0,a0,-1390 # 80008338 <states.0+0x58>
    800028ae:	ffffe097          	auipc	ra,0xffffe
    800028b2:	c92080e7          	jalr	-878(ra) # 80000540 <panic>
    if(killed(p))
    800028b6:	00000097          	auipc	ra,0x0
    800028ba:	a46080e7          	jalr	-1466(ra) # 800022fc <killed>
    800028be:	e921                	bnez	a0,8000290e <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028c0:	6cb8                	ld	a4,88(s1)
    800028c2:	6f1c                	ld	a5,24(a4)
    800028c4:	0791                	addi	a5,a5,4
    800028c6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d0:	10079073          	csrw	sstatus,a5
    syscall();
    800028d4:	00000097          	auipc	ra,0x0
    800028d8:	2d4080e7          	jalr	724(ra) # 80002ba8 <syscall>
  if(killed(p))
    800028dc:	8526                	mv	a0,s1
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	a1e080e7          	jalr	-1506(ra) # 800022fc <killed>
    800028e6:	c911                	beqz	a0,800028fa <usertrap+0xac>
    800028e8:	4901                	li	s2,0
    exit(-1);
    800028ea:	557d                	li	a0,-1
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	89c080e7          	jalr	-1892(ra) # 80002188 <exit>
  if(which_dev == 2)
    800028f4:	4789                	li	a5,2
    800028f6:	04f90f63          	beq	s2,a5,80002954 <usertrap+0x106>
  usertrapret();
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	dd6080e7          	jalr	-554(ra) # 800026d0 <usertrapret>
}
    80002902:	60e2                	ld	ra,24(sp)
    80002904:	6442                	ld	s0,16(sp)
    80002906:	64a2                	ld	s1,8(sp)
    80002908:	6902                	ld	s2,0(sp)
    8000290a:	6105                	addi	sp,sp,32
    8000290c:	8082                	ret
      exit(-1);
    8000290e:	557d                	li	a0,-1
    80002910:	00000097          	auipc	ra,0x0
    80002914:	878080e7          	jalr	-1928(ra) # 80002188 <exit>
    80002918:	b765                	j	800028c0 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000291a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000291e:	5890                	lw	a2,48(s1)
    80002920:	00006517          	auipc	a0,0x6
    80002924:	a3850513          	addi	a0,a0,-1480 # 80008358 <states.0+0x78>
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	c62080e7          	jalr	-926(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002930:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002934:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002938:	00006517          	auipc	a0,0x6
    8000293c:	a5050513          	addi	a0,a0,-1456 # 80008388 <states.0+0xa8>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c4a080e7          	jalr	-950(ra) # 8000058a <printf>
    setkilled(p);
    80002948:	8526                	mv	a0,s1
    8000294a:	00000097          	auipc	ra,0x0
    8000294e:	986080e7          	jalr	-1658(ra) # 800022d0 <setkilled>
    80002952:	b769                	j	800028dc <usertrap+0x8e>
    yield();
    80002954:	fffff097          	auipc	ra,0xfffff
    80002958:	6c4080e7          	jalr	1732(ra) # 80002018 <yield>
    8000295c:	bf79                	j	800028fa <usertrap+0xac>

000000008000295e <kerneltrap>:
{
    8000295e:	7179                	addi	sp,sp,-48
    80002960:	f406                	sd	ra,40(sp)
    80002962:	f022                	sd	s0,32(sp)
    80002964:	ec26                	sd	s1,24(sp)
    80002966:	e84a                	sd	s2,16(sp)
    80002968:	e44e                	sd	s3,8(sp)
    8000296a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000296c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002970:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002974:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002978:	1004f793          	andi	a5,s1,256
    8000297c:	cb85                	beqz	a5,800029ac <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002982:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002984:	ef85                	bnez	a5,800029bc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	e26080e7          	jalr	-474(ra) # 800027ac <devintr>
    8000298e:	cd1d                	beqz	a0,800029cc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002990:	4789                	li	a5,2
    80002992:	06f50a63          	beq	a0,a5,80002a06 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002996:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299a:	10049073          	csrw	sstatus,s1
}
    8000299e:	70a2                	ld	ra,40(sp)
    800029a0:	7402                	ld	s0,32(sp)
    800029a2:	64e2                	ld	s1,24(sp)
    800029a4:	6942                	ld	s2,16(sp)
    800029a6:	69a2                	ld	s3,8(sp)
    800029a8:	6145                	addi	sp,sp,48
    800029aa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	9fc50513          	addi	a0,a0,-1540 # 800083a8 <states.0+0xc8>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	b8c080e7          	jalr	-1140(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	a1450513          	addi	a0,a0,-1516 # 800083d0 <states.0+0xf0>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	b7c080e7          	jalr	-1156(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    800029cc:	85ce                	mv	a1,s3
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	a2250513          	addi	a0,a0,-1502 # 800083f0 <states.0+0x110>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	bb4080e7          	jalr	-1100(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029de:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029e2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029e6:	00006517          	auipc	a0,0x6
    800029ea:	a1a50513          	addi	a0,a0,-1510 # 80008400 <states.0+0x120>
    800029ee:	ffffe097          	auipc	ra,0xffffe
    800029f2:	b9c080e7          	jalr	-1124(ra) # 8000058a <printf>
    panic("kerneltrap");
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	a2250513          	addi	a0,a0,-1502 # 80008418 <states.0+0x138>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b42080e7          	jalr	-1214(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	fa6080e7          	jalr	-90(ra) # 800019ac <myproc>
    80002a0e:	d541                	beqz	a0,80002996 <kerneltrap+0x38>
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	f9c080e7          	jalr	-100(ra) # 800019ac <myproc>
    80002a18:	4d18                	lw	a4,24(a0)
    80002a1a:	4791                	li	a5,4
    80002a1c:	f6f71de3          	bne	a4,a5,80002996 <kerneltrap+0x38>
    yield();
    80002a20:	fffff097          	auipc	ra,0xfffff
    80002a24:	5f8080e7          	jalr	1528(ra) # 80002018 <yield>
    80002a28:	b7bd                	j	80002996 <kerneltrap+0x38>

0000000080002a2a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a2a:	1101                	addi	sp,sp,-32
    80002a2c:	ec06                	sd	ra,24(sp)
    80002a2e:	e822                	sd	s0,16(sp)
    80002a30:	e426                	sd	s1,8(sp)
    80002a32:	1000                	addi	s0,sp,32
    80002a34:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a36:	fffff097          	auipc	ra,0xfffff
    80002a3a:	f76080e7          	jalr	-138(ra) # 800019ac <myproc>
  switch (n)
    80002a3e:	4795                	li	a5,5
    80002a40:	0497e163          	bltu	a5,s1,80002a82 <argraw+0x58>
    80002a44:	048a                	slli	s1,s1,0x2
    80002a46:	00006717          	auipc	a4,0x6
    80002a4a:	a0a70713          	addi	a4,a4,-1526 # 80008450 <states.0+0x170>
    80002a4e:	94ba                	add	s1,s1,a4
    80002a50:	409c                	lw	a5,0(s1)
    80002a52:	97ba                	add	a5,a5,a4
    80002a54:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002a56:	6d3c                	ld	a5,88(a0)
    80002a58:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a5a:	60e2                	ld	ra,24(sp)
    80002a5c:	6442                	ld	s0,16(sp)
    80002a5e:	64a2                	ld	s1,8(sp)
    80002a60:	6105                	addi	sp,sp,32
    80002a62:	8082                	ret
    return p->trapframe->a1;
    80002a64:	6d3c                	ld	a5,88(a0)
    80002a66:	7fa8                	ld	a0,120(a5)
    80002a68:	bfcd                	j	80002a5a <argraw+0x30>
    return p->trapframe->a2;
    80002a6a:	6d3c                	ld	a5,88(a0)
    80002a6c:	63c8                	ld	a0,128(a5)
    80002a6e:	b7f5                	j	80002a5a <argraw+0x30>
    return p->trapframe->a3;
    80002a70:	6d3c                	ld	a5,88(a0)
    80002a72:	67c8                	ld	a0,136(a5)
    80002a74:	b7dd                	j	80002a5a <argraw+0x30>
    return p->trapframe->a4;
    80002a76:	6d3c                	ld	a5,88(a0)
    80002a78:	6bc8                	ld	a0,144(a5)
    80002a7a:	b7c5                	j	80002a5a <argraw+0x30>
    return p->trapframe->a5;
    80002a7c:	6d3c                	ld	a5,88(a0)
    80002a7e:	6fc8                	ld	a0,152(a5)
    80002a80:	bfe9                	j	80002a5a <argraw+0x30>
  panic("argraw");
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	9a650513          	addi	a0,a0,-1626 # 80008428 <states.0+0x148>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	ab6080e7          	jalr	-1354(ra) # 80000540 <panic>

0000000080002a92 <fetchaddr>:
{
    80002a92:	1101                	addi	sp,sp,-32
    80002a94:	ec06                	sd	ra,24(sp)
    80002a96:	e822                	sd	s0,16(sp)
    80002a98:	e426                	sd	s1,8(sp)
    80002a9a:	e04a                	sd	s2,0(sp)
    80002a9c:	1000                	addi	s0,sp,32
    80002a9e:	84aa                	mv	s1,a0
    80002aa0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	f0a080e7          	jalr	-246(ra) # 800019ac <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aaa:	653c                	ld	a5,72(a0)
    80002aac:	02f4f863          	bgeu	s1,a5,80002adc <fetchaddr+0x4a>
    80002ab0:	00848713          	addi	a4,s1,8
    80002ab4:	02e7e663          	bltu	a5,a4,80002ae0 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ab8:	46a1                	li	a3,8
    80002aba:	8626                	mv	a2,s1
    80002abc:	85ca                	mv	a1,s2
    80002abe:	6928                	ld	a0,80(a0)
    80002ac0:	fffff097          	auipc	ra,0xfffff
    80002ac4:	c38080e7          	jalr	-968(ra) # 800016f8 <copyin>
    80002ac8:	00a03533          	snez	a0,a0
    80002acc:	40a00533          	neg	a0,a0
}
    80002ad0:	60e2                	ld	ra,24(sp)
    80002ad2:	6442                	ld	s0,16(sp)
    80002ad4:	64a2                	ld	s1,8(sp)
    80002ad6:	6902                	ld	s2,0(sp)
    80002ad8:	6105                	addi	sp,sp,32
    80002ada:	8082                	ret
    return -1;
    80002adc:	557d                	li	a0,-1
    80002ade:	bfcd                	j	80002ad0 <fetchaddr+0x3e>
    80002ae0:	557d                	li	a0,-1
    80002ae2:	b7fd                	j	80002ad0 <fetchaddr+0x3e>

0000000080002ae4 <fetchstr>:
{
    80002ae4:	7179                	addi	sp,sp,-48
    80002ae6:	f406                	sd	ra,40(sp)
    80002ae8:	f022                	sd	s0,32(sp)
    80002aea:	ec26                	sd	s1,24(sp)
    80002aec:	e84a                	sd	s2,16(sp)
    80002aee:	e44e                	sd	s3,8(sp)
    80002af0:	1800                	addi	s0,sp,48
    80002af2:	892a                	mv	s2,a0
    80002af4:	84ae                	mv	s1,a1
    80002af6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002af8:	fffff097          	auipc	ra,0xfffff
    80002afc:	eb4080e7          	jalr	-332(ra) # 800019ac <myproc>
  if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b00:	86ce                	mv	a3,s3
    80002b02:	864a                	mv	a2,s2
    80002b04:	85a6                	mv	a1,s1
    80002b06:	6928                	ld	a0,80(a0)
    80002b08:	fffff097          	auipc	ra,0xfffff
    80002b0c:	c7e080e7          	jalr	-898(ra) # 80001786 <copyinstr>
    80002b10:	00054e63          	bltz	a0,80002b2c <fetchstr+0x48>
  return strlen(buf);
    80002b14:	8526                	mv	a0,s1
    80002b16:	ffffe097          	auipc	ra,0xffffe
    80002b1a:	338080e7          	jalr	824(ra) # 80000e4e <strlen>
}
    80002b1e:	70a2                	ld	ra,40(sp)
    80002b20:	7402                	ld	s0,32(sp)
    80002b22:	64e2                	ld	s1,24(sp)
    80002b24:	6942                	ld	s2,16(sp)
    80002b26:	69a2                	ld	s3,8(sp)
    80002b28:	6145                	addi	sp,sp,48
    80002b2a:	8082                	ret
    return -1;
    80002b2c:	557d                	li	a0,-1
    80002b2e:	bfc5                	j	80002b1e <fetchstr+0x3a>

0000000080002b30 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002b30:	1101                	addi	sp,sp,-32
    80002b32:	ec06                	sd	ra,24(sp)
    80002b34:	e822                	sd	s0,16(sp)
    80002b36:	e426                	sd	s1,8(sp)
    80002b38:	1000                	addi	s0,sp,32
    80002b3a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	eee080e7          	jalr	-274(ra) # 80002a2a <argraw>
    80002b44:	c088                	sw	a0,0(s1)
}
    80002b46:	60e2                	ld	ra,24(sp)
    80002b48:	6442                	ld	s0,16(sp)
    80002b4a:	64a2                	ld	s1,8(sp)
    80002b4c:	6105                	addi	sp,sp,32
    80002b4e:	8082                	ret

0000000080002b50 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002b50:	1101                	addi	sp,sp,-32
    80002b52:	ec06                	sd	ra,24(sp)
    80002b54:	e822                	sd	s0,16(sp)
    80002b56:	e426                	sd	s1,8(sp)
    80002b58:	1000                	addi	s0,sp,32
    80002b5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	ece080e7          	jalr	-306(ra) # 80002a2a <argraw>
    80002b64:	e088                	sd	a0,0(s1)
}
    80002b66:	60e2                	ld	ra,24(sp)
    80002b68:	6442                	ld	s0,16(sp)
    80002b6a:	64a2                	ld	s1,8(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret

0000000080002b70 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002b70:	7179                	addi	sp,sp,-48
    80002b72:	f406                	sd	ra,40(sp)
    80002b74:	f022                	sd	s0,32(sp)
    80002b76:	ec26                	sd	s1,24(sp)
    80002b78:	e84a                	sd	s2,16(sp)
    80002b7a:	1800                	addi	s0,sp,48
    80002b7c:	84ae                	mv	s1,a1
    80002b7e:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b80:	fd840593          	addi	a1,s0,-40
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	fcc080e7          	jalr	-52(ra) # 80002b50 <argaddr>
  return fetchstr(addr, buf, max);
    80002b8c:	864a                	mv	a2,s2
    80002b8e:	85a6                	mv	a1,s1
    80002b90:	fd843503          	ld	a0,-40(s0)
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	f50080e7          	jalr	-176(ra) # 80002ae4 <fetchstr>
}
    80002b9c:	70a2                	ld	ra,40(sp)
    80002b9e:	7402                	ld	s0,32(sp)
    80002ba0:	64e2                	ld	s1,24(sp)
    80002ba2:	6942                	ld	s2,16(sp)
    80002ba4:	6145                	addi	sp,sp,48
    80002ba6:	8082                	ret

0000000080002ba8 <syscall>:
    [SYS_close] sys_close,

};

void syscall(void)
{
    80002ba8:	1101                	addi	sp,sp,-32
    80002baa:	ec06                	sd	ra,24(sp)
    80002bac:	e822                	sd	s0,16(sp)
    80002bae:	e426                	sd	s1,8(sp)
    80002bb0:	e04a                	sd	s2,0(sp)
    80002bb2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	df8080e7          	jalr	-520(ra) # 800019ac <myproc>
    80002bbc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bbe:	05853903          	ld	s2,88(a0)
    80002bc2:	0a893783          	ld	a5,168(s2)
    80002bc6:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002bca:	37fd                	addiw	a5,a5,-1
    80002bcc:	4755                	li	a4,21
    80002bce:	00f76f63          	bltu	a4,a5,80002bec <syscall+0x44>
    80002bd2:	00369713          	slli	a4,a3,0x3
    80002bd6:	00006797          	auipc	a5,0x6
    80002bda:	89278793          	addi	a5,a5,-1902 # 80008468 <syscalls>
    80002bde:	97ba                	add	a5,a5,a4
    80002be0:	639c                	ld	a5,0(a5)
    80002be2:	c789                	beqz	a5,80002bec <syscall+0x44>
  {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002be4:	9782                	jalr	a5
    80002be6:	06a93823          	sd	a0,112(s2)
    80002bea:	a839                	j	80002c08 <syscall+0x60>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002bec:	15848613          	addi	a2,s1,344
    80002bf0:	588c                	lw	a1,48(s1)
    80002bf2:	00006517          	auipc	a0,0x6
    80002bf6:	83e50513          	addi	a0,a0,-1986 # 80008430 <states.0+0x150>
    80002bfa:	ffffe097          	auipc	ra,0xffffe
    80002bfe:	990080e7          	jalr	-1648(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c02:	6cbc                	ld	a5,88(s1)
    80002c04:	577d                	li	a4,-1
    80002c06:	fbb8                	sd	a4,112(a5)
  }
}
    80002c08:	60e2                	ld	ra,24(sp)
    80002c0a:	6442                	ld	s0,16(sp)
    80002c0c:	64a2                	ld	s1,8(sp)
    80002c0e:	6902                	ld	s2,0(sp)
    80002c10:	6105                	addi	sp,sp,32
    80002c12:	8082                	ret

0000000080002c14 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c14:	1101                	addi	sp,sp,-32
    80002c16:	ec06                	sd	ra,24(sp)
    80002c18:	e822                	sd	s0,16(sp)
    80002c1a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c1c:	fec40593          	addi	a1,s0,-20
    80002c20:	4501                	li	a0,0
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	f0e080e7          	jalr	-242(ra) # 80002b30 <argint>
  exit(n);
    80002c2a:	fec42503          	lw	a0,-20(s0)
    80002c2e:	fffff097          	auipc	ra,0xfffff
    80002c32:	55a080e7          	jalr	1370(ra) # 80002188 <exit>
  return 0; // not reached
}
    80002c36:	4501                	li	a0,0
    80002c38:	60e2                	ld	ra,24(sp)
    80002c3a:	6442                	ld	s0,16(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret

0000000080002c40 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c40:	1141                	addi	sp,sp,-16
    80002c42:	e406                	sd	ra,8(sp)
    80002c44:	e022                	sd	s0,0(sp)
    80002c46:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	d64080e7          	jalr	-668(ra) # 800019ac <myproc>
}
    80002c50:	5908                	lw	a0,48(a0)
    80002c52:	60a2                	ld	ra,8(sp)
    80002c54:	6402                	ld	s0,0(sp)
    80002c56:	0141                	addi	sp,sp,16
    80002c58:	8082                	ret

0000000080002c5a <sys_fork>:

uint64
sys_fork(void)
{
    80002c5a:	1141                	addi	sp,sp,-16
    80002c5c:	e406                	sd	ra,8(sp)
    80002c5e:	e022                	sd	s0,0(sp)
    80002c60:	0800                	addi	s0,sp,16
  return fork();
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	100080e7          	jalr	256(ra) # 80001d62 <fork>
}
    80002c6a:	60a2                	ld	ra,8(sp)
    80002c6c:	6402                	ld	s0,0(sp)
    80002c6e:	0141                	addi	sp,sp,16
    80002c70:	8082                	ret

0000000080002c72 <sys_wait>:

uint64
sys_wait(void)
{
    80002c72:	1101                	addi	sp,sp,-32
    80002c74:	ec06                	sd	ra,24(sp)
    80002c76:	e822                	sd	s0,16(sp)
    80002c78:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c7a:	fe840593          	addi	a1,s0,-24
    80002c7e:	4501                	li	a0,0
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	ed0080e7          	jalr	-304(ra) # 80002b50 <argaddr>
  return wait(p);
    80002c88:	fe843503          	ld	a0,-24(s0)
    80002c8c:	fffff097          	auipc	ra,0xfffff
    80002c90:	6a2080e7          	jalr	1698(ra) # 8000232e <wait>
}
    80002c94:	60e2                	ld	ra,24(sp)
    80002c96:	6442                	ld	s0,16(sp)
    80002c98:	6105                	addi	sp,sp,32
    80002c9a:	8082                	ret

0000000080002c9c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c9c:	7179                	addi	sp,sp,-48
    80002c9e:	f406                	sd	ra,40(sp)
    80002ca0:	f022                	sd	s0,32(sp)
    80002ca2:	ec26                	sd	s1,24(sp)
    80002ca4:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002ca6:	fdc40593          	addi	a1,s0,-36
    80002caa:	4501                	li	a0,0
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	e84080e7          	jalr	-380(ra) # 80002b30 <argint>
  addr = myproc()->sz;
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	cf8080e7          	jalr	-776(ra) # 800019ac <myproc>
    80002cbc:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002cbe:	fdc42503          	lw	a0,-36(s0)
    80002cc2:	fffff097          	auipc	ra,0xfffff
    80002cc6:	044080e7          	jalr	68(ra) # 80001d06 <growproc>
    80002cca:	00054863          	bltz	a0,80002cda <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002cce:	8526                	mv	a0,s1
    80002cd0:	70a2                	ld	ra,40(sp)
    80002cd2:	7402                	ld	s0,32(sp)
    80002cd4:	64e2                	ld	s1,24(sp)
    80002cd6:	6145                	addi	sp,sp,48
    80002cd8:	8082                	ret
    return -1;
    80002cda:	54fd                	li	s1,-1
    80002cdc:	bfcd                	j	80002cce <sys_sbrk+0x32>

0000000080002cde <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cde:	7139                	addi	sp,sp,-64
    80002ce0:	fc06                	sd	ra,56(sp)
    80002ce2:	f822                	sd	s0,48(sp)
    80002ce4:	f426                	sd	s1,40(sp)
    80002ce6:	f04a                	sd	s2,32(sp)
    80002ce8:	ec4e                	sd	s3,24(sp)
    80002cea:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cec:	fcc40593          	addi	a1,s0,-52
    80002cf0:	4501                	li	a0,0
    80002cf2:	00000097          	auipc	ra,0x0
    80002cf6:	e3e080e7          	jalr	-450(ra) # 80002b30 <argint>
  acquire(&tickslock);
    80002cfa:	00014517          	auipc	a0,0x14
    80002cfe:	ca650513          	addi	a0,a0,-858 # 800169a0 <tickslock>
    80002d02:	ffffe097          	auipc	ra,0xffffe
    80002d06:	ed4080e7          	jalr	-300(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002d0a:	00006917          	auipc	s2,0x6
    80002d0e:	bf692903          	lw	s2,-1034(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    80002d12:	fcc42783          	lw	a5,-52(s0)
    80002d16:	cf9d                	beqz	a5,80002d54 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d18:	00014997          	auipc	s3,0x14
    80002d1c:	c8898993          	addi	s3,s3,-888 # 800169a0 <tickslock>
    80002d20:	00006497          	auipc	s1,0x6
    80002d24:	be048493          	addi	s1,s1,-1056 # 80008900 <ticks>
    if (killed(myproc()))
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	5cc080e7          	jalr	1484(ra) # 800022fc <killed>
    80002d38:	ed15                	bnez	a0,80002d74 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002d3a:	85ce                	mv	a1,s3
    80002d3c:	8526                	mv	a0,s1
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	316080e7          	jalr	790(ra) # 80002054 <sleep>
  while (ticks - ticks0 < n)
    80002d46:	409c                	lw	a5,0(s1)
    80002d48:	412787bb          	subw	a5,a5,s2
    80002d4c:	fcc42703          	lw	a4,-52(s0)
    80002d50:	fce7ece3          	bltu	a5,a4,80002d28 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002d54:	00014517          	auipc	a0,0x14
    80002d58:	c4c50513          	addi	a0,a0,-948 # 800169a0 <tickslock>
    80002d5c:	ffffe097          	auipc	ra,0xffffe
    80002d60:	f2e080e7          	jalr	-210(ra) # 80000c8a <release>
  return 0;
    80002d64:	4501                	li	a0,0
}
    80002d66:	70e2                	ld	ra,56(sp)
    80002d68:	7442                	ld	s0,48(sp)
    80002d6a:	74a2                	ld	s1,40(sp)
    80002d6c:	7902                	ld	s2,32(sp)
    80002d6e:	69e2                	ld	s3,24(sp)
    80002d70:	6121                	addi	sp,sp,64
    80002d72:	8082                	ret
      release(&tickslock);
    80002d74:	00014517          	auipc	a0,0x14
    80002d78:	c2c50513          	addi	a0,a0,-980 # 800169a0 <tickslock>
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	f0e080e7          	jalr	-242(ra) # 80000c8a <release>
      return -1;
    80002d84:	557d                	li	a0,-1
    80002d86:	b7c5                	j	80002d66 <sys_sleep+0x88>

0000000080002d88 <sys_kill>:

uint64
sys_kill(void)
{
    80002d88:	1101                	addi	sp,sp,-32
    80002d8a:	ec06                	sd	ra,24(sp)
    80002d8c:	e822                	sd	s0,16(sp)
    80002d8e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d90:	fec40593          	addi	a1,s0,-20
    80002d94:	4501                	li	a0,0
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	d9a080e7          	jalr	-614(ra) # 80002b30 <argint>
  return kill(pid);
    80002d9e:	fec42503          	lw	a0,-20(s0)
    80002da2:	fffff097          	auipc	ra,0xfffff
    80002da6:	4bc080e7          	jalr	1212(ra) # 8000225e <kill>
}
    80002daa:	60e2                	ld	ra,24(sp)
    80002dac:	6442                	ld	s0,16(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <sys_ps>:

uint64 sys_ps(void)
{
    80002db2:	1141                	addi	sp,sp,-16
    80002db4:	e406                	sd	ra,8(sp)
    80002db6:	e022                	sd	s0,0(sp)
    80002db8:	0800                	addi	s0,sp,16
  pss();
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	7fe080e7          	jalr	2046(ra) # 800025b8 <pss>
  return 0;
}
    80002dc2:	4501                	li	a0,0
    80002dc4:	60a2                	ld	ra,8(sp)
    80002dc6:	6402                	ld	s0,0(sp)
    80002dc8:	0141                	addi	sp,sp,16
    80002dca:	8082                	ret

0000000080002dcc <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dd6:	00014517          	auipc	a0,0x14
    80002dda:	bca50513          	addi	a0,a0,-1078 # 800169a0 <tickslock>
    80002dde:	ffffe097          	auipc	ra,0xffffe
    80002de2:	df8080e7          	jalr	-520(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002de6:	00006497          	auipc	s1,0x6
    80002dea:	b1a4a483          	lw	s1,-1254(s1) # 80008900 <ticks>
  release(&tickslock);
    80002dee:	00014517          	auipc	a0,0x14
    80002df2:	bb250513          	addi	a0,a0,-1102 # 800169a0 <tickslock>
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	e94080e7          	jalr	-364(ra) # 80000c8a <release>
  return xticks;
}
    80002dfe:	02049513          	slli	a0,s1,0x20
    80002e02:	9101                	srli	a0,a0,0x20
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret

0000000080002e0e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e0e:	7179                	addi	sp,sp,-48
    80002e10:	f406                	sd	ra,40(sp)
    80002e12:	f022                	sd	s0,32(sp)
    80002e14:	ec26                	sd	s1,24(sp)
    80002e16:	e84a                	sd	s2,16(sp)
    80002e18:	e44e                	sd	s3,8(sp)
    80002e1a:	e052                	sd	s4,0(sp)
    80002e1c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e1e:	00005597          	auipc	a1,0x5
    80002e22:	70258593          	addi	a1,a1,1794 # 80008520 <syscalls+0xb8>
    80002e26:	00014517          	auipc	a0,0x14
    80002e2a:	b9250513          	addi	a0,a0,-1134 # 800169b8 <bcache>
    80002e2e:	ffffe097          	auipc	ra,0xffffe
    80002e32:	d18080e7          	jalr	-744(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e36:	0001c797          	auipc	a5,0x1c
    80002e3a:	b8278793          	addi	a5,a5,-1150 # 8001e9b8 <bcache+0x8000>
    80002e3e:	0001c717          	auipc	a4,0x1c
    80002e42:	de270713          	addi	a4,a4,-542 # 8001ec20 <bcache+0x8268>
    80002e46:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e4a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e4e:	00014497          	auipc	s1,0x14
    80002e52:	b8248493          	addi	s1,s1,-1150 # 800169d0 <bcache+0x18>
    b->next = bcache.head.next;
    80002e56:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e58:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e5a:	00005a17          	auipc	s4,0x5
    80002e5e:	6cea0a13          	addi	s4,s4,1742 # 80008528 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002e62:	2b893783          	ld	a5,696(s2)
    80002e66:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e68:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e6c:	85d2                	mv	a1,s4
    80002e6e:	01048513          	addi	a0,s1,16
    80002e72:	00001097          	auipc	ra,0x1
    80002e76:	4c8080e7          	jalr	1224(ra) # 8000433a <initsleeplock>
    bcache.head.next->prev = b;
    80002e7a:	2b893783          	ld	a5,696(s2)
    80002e7e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e80:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e84:	45848493          	addi	s1,s1,1112
    80002e88:	fd349de3          	bne	s1,s3,80002e62 <binit+0x54>
  }
}
    80002e8c:	70a2                	ld	ra,40(sp)
    80002e8e:	7402                	ld	s0,32(sp)
    80002e90:	64e2                	ld	s1,24(sp)
    80002e92:	6942                	ld	s2,16(sp)
    80002e94:	69a2                	ld	s3,8(sp)
    80002e96:	6a02                	ld	s4,0(sp)
    80002e98:	6145                	addi	sp,sp,48
    80002e9a:	8082                	ret

0000000080002e9c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e9c:	7179                	addi	sp,sp,-48
    80002e9e:	f406                	sd	ra,40(sp)
    80002ea0:	f022                	sd	s0,32(sp)
    80002ea2:	ec26                	sd	s1,24(sp)
    80002ea4:	e84a                	sd	s2,16(sp)
    80002ea6:	e44e                	sd	s3,8(sp)
    80002ea8:	1800                	addi	s0,sp,48
    80002eaa:	892a                	mv	s2,a0
    80002eac:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002eae:	00014517          	auipc	a0,0x14
    80002eb2:	b0a50513          	addi	a0,a0,-1270 # 800169b8 <bcache>
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	d20080e7          	jalr	-736(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ebe:	0001c497          	auipc	s1,0x1c
    80002ec2:	db24b483          	ld	s1,-590(s1) # 8001ec70 <bcache+0x82b8>
    80002ec6:	0001c797          	auipc	a5,0x1c
    80002eca:	d5a78793          	addi	a5,a5,-678 # 8001ec20 <bcache+0x8268>
    80002ece:	02f48f63          	beq	s1,a5,80002f0c <bread+0x70>
    80002ed2:	873e                	mv	a4,a5
    80002ed4:	a021                	j	80002edc <bread+0x40>
    80002ed6:	68a4                	ld	s1,80(s1)
    80002ed8:	02e48a63          	beq	s1,a4,80002f0c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002edc:	449c                	lw	a5,8(s1)
    80002ede:	ff279ce3          	bne	a5,s2,80002ed6 <bread+0x3a>
    80002ee2:	44dc                	lw	a5,12(s1)
    80002ee4:	ff3799e3          	bne	a5,s3,80002ed6 <bread+0x3a>
      b->refcnt++;
    80002ee8:	40bc                	lw	a5,64(s1)
    80002eea:	2785                	addiw	a5,a5,1
    80002eec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002eee:	00014517          	auipc	a0,0x14
    80002ef2:	aca50513          	addi	a0,a0,-1334 # 800169b8 <bcache>
    80002ef6:	ffffe097          	auipc	ra,0xffffe
    80002efa:	d94080e7          	jalr	-620(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002efe:	01048513          	addi	a0,s1,16
    80002f02:	00001097          	auipc	ra,0x1
    80002f06:	472080e7          	jalr	1138(ra) # 80004374 <acquiresleep>
      return b;
    80002f0a:	a8b9                	j	80002f68 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f0c:	0001c497          	auipc	s1,0x1c
    80002f10:	d5c4b483          	ld	s1,-676(s1) # 8001ec68 <bcache+0x82b0>
    80002f14:	0001c797          	auipc	a5,0x1c
    80002f18:	d0c78793          	addi	a5,a5,-756 # 8001ec20 <bcache+0x8268>
    80002f1c:	00f48863          	beq	s1,a5,80002f2c <bread+0x90>
    80002f20:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f22:	40bc                	lw	a5,64(s1)
    80002f24:	cf81                	beqz	a5,80002f3c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f26:	64a4                	ld	s1,72(s1)
    80002f28:	fee49de3          	bne	s1,a4,80002f22 <bread+0x86>
  panic("bget: no buffers");
    80002f2c:	00005517          	auipc	a0,0x5
    80002f30:	60450513          	addi	a0,a0,1540 # 80008530 <syscalls+0xc8>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	60c080e7          	jalr	1548(ra) # 80000540 <panic>
      b->dev = dev;
    80002f3c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f40:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f44:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f48:	4785                	li	a5,1
    80002f4a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f4c:	00014517          	auipc	a0,0x14
    80002f50:	a6c50513          	addi	a0,a0,-1428 # 800169b8 <bcache>
    80002f54:	ffffe097          	auipc	ra,0xffffe
    80002f58:	d36080e7          	jalr	-714(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002f5c:	01048513          	addi	a0,s1,16
    80002f60:	00001097          	auipc	ra,0x1
    80002f64:	414080e7          	jalr	1044(ra) # 80004374 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f68:	409c                	lw	a5,0(s1)
    80002f6a:	cb89                	beqz	a5,80002f7c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f6c:	8526                	mv	a0,s1
    80002f6e:	70a2                	ld	ra,40(sp)
    80002f70:	7402                	ld	s0,32(sp)
    80002f72:	64e2                	ld	s1,24(sp)
    80002f74:	6942                	ld	s2,16(sp)
    80002f76:	69a2                	ld	s3,8(sp)
    80002f78:	6145                	addi	sp,sp,48
    80002f7a:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f7c:	4581                	li	a1,0
    80002f7e:	8526                	mv	a0,s1
    80002f80:	00003097          	auipc	ra,0x3
    80002f84:	fe2080e7          	jalr	-30(ra) # 80005f62 <virtio_disk_rw>
    b->valid = 1;
    80002f88:	4785                	li	a5,1
    80002f8a:	c09c                	sw	a5,0(s1)
  return b;
    80002f8c:	b7c5                	j	80002f6c <bread+0xd0>

0000000080002f8e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f8e:	1101                	addi	sp,sp,-32
    80002f90:	ec06                	sd	ra,24(sp)
    80002f92:	e822                	sd	s0,16(sp)
    80002f94:	e426                	sd	s1,8(sp)
    80002f96:	1000                	addi	s0,sp,32
    80002f98:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f9a:	0541                	addi	a0,a0,16
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	472080e7          	jalr	1138(ra) # 8000440e <holdingsleep>
    80002fa4:	cd01                	beqz	a0,80002fbc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fa6:	4585                	li	a1,1
    80002fa8:	8526                	mv	a0,s1
    80002faa:	00003097          	auipc	ra,0x3
    80002fae:	fb8080e7          	jalr	-72(ra) # 80005f62 <virtio_disk_rw>
}
    80002fb2:	60e2                	ld	ra,24(sp)
    80002fb4:	6442                	ld	s0,16(sp)
    80002fb6:	64a2                	ld	s1,8(sp)
    80002fb8:	6105                	addi	sp,sp,32
    80002fba:	8082                	ret
    panic("bwrite");
    80002fbc:	00005517          	auipc	a0,0x5
    80002fc0:	58c50513          	addi	a0,a0,1420 # 80008548 <syscalls+0xe0>
    80002fc4:	ffffd097          	auipc	ra,0xffffd
    80002fc8:	57c080e7          	jalr	1404(ra) # 80000540 <panic>

0000000080002fcc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002fcc:	1101                	addi	sp,sp,-32
    80002fce:	ec06                	sd	ra,24(sp)
    80002fd0:	e822                	sd	s0,16(sp)
    80002fd2:	e426                	sd	s1,8(sp)
    80002fd4:	e04a                	sd	s2,0(sp)
    80002fd6:	1000                	addi	s0,sp,32
    80002fd8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fda:	01050913          	addi	s2,a0,16
    80002fde:	854a                	mv	a0,s2
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	42e080e7          	jalr	1070(ra) # 8000440e <holdingsleep>
    80002fe8:	c92d                	beqz	a0,8000305a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002fea:	854a                	mv	a0,s2
    80002fec:	00001097          	auipc	ra,0x1
    80002ff0:	3de080e7          	jalr	990(ra) # 800043ca <releasesleep>

  acquire(&bcache.lock);
    80002ff4:	00014517          	auipc	a0,0x14
    80002ff8:	9c450513          	addi	a0,a0,-1596 # 800169b8 <bcache>
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	bda080e7          	jalr	-1062(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003004:	40bc                	lw	a5,64(s1)
    80003006:	37fd                	addiw	a5,a5,-1
    80003008:	0007871b          	sext.w	a4,a5
    8000300c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000300e:	eb05                	bnez	a4,8000303e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003010:	68bc                	ld	a5,80(s1)
    80003012:	64b8                	ld	a4,72(s1)
    80003014:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003016:	64bc                	ld	a5,72(s1)
    80003018:	68b8                	ld	a4,80(s1)
    8000301a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000301c:	0001c797          	auipc	a5,0x1c
    80003020:	99c78793          	addi	a5,a5,-1636 # 8001e9b8 <bcache+0x8000>
    80003024:	2b87b703          	ld	a4,696(a5)
    80003028:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000302a:	0001c717          	auipc	a4,0x1c
    8000302e:	bf670713          	addi	a4,a4,-1034 # 8001ec20 <bcache+0x8268>
    80003032:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003034:	2b87b703          	ld	a4,696(a5)
    80003038:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000303a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000303e:	00014517          	auipc	a0,0x14
    80003042:	97a50513          	addi	a0,a0,-1670 # 800169b8 <bcache>
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	c44080e7          	jalr	-956(ra) # 80000c8a <release>
}
    8000304e:	60e2                	ld	ra,24(sp)
    80003050:	6442                	ld	s0,16(sp)
    80003052:	64a2                	ld	s1,8(sp)
    80003054:	6902                	ld	s2,0(sp)
    80003056:	6105                	addi	sp,sp,32
    80003058:	8082                	ret
    panic("brelse");
    8000305a:	00005517          	auipc	a0,0x5
    8000305e:	4f650513          	addi	a0,a0,1270 # 80008550 <syscalls+0xe8>
    80003062:	ffffd097          	auipc	ra,0xffffd
    80003066:	4de080e7          	jalr	1246(ra) # 80000540 <panic>

000000008000306a <bpin>:

void
bpin(struct buf *b) {
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	1000                	addi	s0,sp,32
    80003074:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	94250513          	addi	a0,a0,-1726 # 800169b8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	b58080e7          	jalr	-1192(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003086:	40bc                	lw	a5,64(s1)
    80003088:	2785                	addiw	a5,a5,1
    8000308a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	92c50513          	addi	a0,a0,-1748 # 800169b8 <bcache>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	bf6080e7          	jalr	-1034(ra) # 80000c8a <release>
}
    8000309c:	60e2                	ld	ra,24(sp)
    8000309e:	6442                	ld	s0,16(sp)
    800030a0:	64a2                	ld	s1,8(sp)
    800030a2:	6105                	addi	sp,sp,32
    800030a4:	8082                	ret

00000000800030a6 <bunpin>:

void
bunpin(struct buf *b) {
    800030a6:	1101                	addi	sp,sp,-32
    800030a8:	ec06                	sd	ra,24(sp)
    800030aa:	e822                	sd	s0,16(sp)
    800030ac:	e426                	sd	s1,8(sp)
    800030ae:	1000                	addi	s0,sp,32
    800030b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	90650513          	addi	a0,a0,-1786 # 800169b8 <bcache>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	b1c080e7          	jalr	-1252(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030c2:	40bc                	lw	a5,64(s1)
    800030c4:	37fd                	addiw	a5,a5,-1
    800030c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030c8:	00014517          	auipc	a0,0x14
    800030cc:	8f050513          	addi	a0,a0,-1808 # 800169b8 <bcache>
    800030d0:	ffffe097          	auipc	ra,0xffffe
    800030d4:	bba080e7          	jalr	-1094(ra) # 80000c8a <release>
}
    800030d8:	60e2                	ld	ra,24(sp)
    800030da:	6442                	ld	s0,16(sp)
    800030dc:	64a2                	ld	s1,8(sp)
    800030de:	6105                	addi	sp,sp,32
    800030e0:	8082                	ret

00000000800030e2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800030e2:	1101                	addi	sp,sp,-32
    800030e4:	ec06                	sd	ra,24(sp)
    800030e6:	e822                	sd	s0,16(sp)
    800030e8:	e426                	sd	s1,8(sp)
    800030ea:	e04a                	sd	s2,0(sp)
    800030ec:	1000                	addi	s0,sp,32
    800030ee:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800030f0:	00d5d59b          	srliw	a1,a1,0xd
    800030f4:	0001c797          	auipc	a5,0x1c
    800030f8:	fa07a783          	lw	a5,-96(a5) # 8001f094 <sb+0x1c>
    800030fc:	9dbd                	addw	a1,a1,a5
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	d9e080e7          	jalr	-610(ra) # 80002e9c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003106:	0074f713          	andi	a4,s1,7
    8000310a:	4785                	li	a5,1
    8000310c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003110:	14ce                	slli	s1,s1,0x33
    80003112:	90d9                	srli	s1,s1,0x36
    80003114:	00950733          	add	a4,a0,s1
    80003118:	05874703          	lbu	a4,88(a4)
    8000311c:	00e7f6b3          	and	a3,a5,a4
    80003120:	c69d                	beqz	a3,8000314e <bfree+0x6c>
    80003122:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003124:	94aa                	add	s1,s1,a0
    80003126:	fff7c793          	not	a5,a5
    8000312a:	8f7d                	and	a4,a4,a5
    8000312c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003130:	00001097          	auipc	ra,0x1
    80003134:	126080e7          	jalr	294(ra) # 80004256 <log_write>
  brelse(bp);
    80003138:	854a                	mv	a0,s2
    8000313a:	00000097          	auipc	ra,0x0
    8000313e:	e92080e7          	jalr	-366(ra) # 80002fcc <brelse>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	64a2                	ld	s1,8(sp)
    80003148:	6902                	ld	s2,0(sp)
    8000314a:	6105                	addi	sp,sp,32
    8000314c:	8082                	ret
    panic("freeing free block");
    8000314e:	00005517          	auipc	a0,0x5
    80003152:	40a50513          	addi	a0,a0,1034 # 80008558 <syscalls+0xf0>
    80003156:	ffffd097          	auipc	ra,0xffffd
    8000315a:	3ea080e7          	jalr	1002(ra) # 80000540 <panic>

000000008000315e <balloc>:
{
    8000315e:	711d                	addi	sp,sp,-96
    80003160:	ec86                	sd	ra,88(sp)
    80003162:	e8a2                	sd	s0,80(sp)
    80003164:	e4a6                	sd	s1,72(sp)
    80003166:	e0ca                	sd	s2,64(sp)
    80003168:	fc4e                	sd	s3,56(sp)
    8000316a:	f852                	sd	s4,48(sp)
    8000316c:	f456                	sd	s5,40(sp)
    8000316e:	f05a                	sd	s6,32(sp)
    80003170:	ec5e                	sd	s7,24(sp)
    80003172:	e862                	sd	s8,16(sp)
    80003174:	e466                	sd	s9,8(sp)
    80003176:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003178:	0001c797          	auipc	a5,0x1c
    8000317c:	f047a783          	lw	a5,-252(a5) # 8001f07c <sb+0x4>
    80003180:	cff5                	beqz	a5,8000327c <balloc+0x11e>
    80003182:	8baa                	mv	s7,a0
    80003184:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003186:	0001cb17          	auipc	s6,0x1c
    8000318a:	ef2b0b13          	addi	s6,s6,-270 # 8001f078 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000318e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003190:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003192:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003194:	6c89                	lui	s9,0x2
    80003196:	a061                	j	8000321e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003198:	97ca                	add	a5,a5,s2
    8000319a:	8e55                	or	a2,a2,a3
    8000319c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800031a0:	854a                	mv	a0,s2
    800031a2:	00001097          	auipc	ra,0x1
    800031a6:	0b4080e7          	jalr	180(ra) # 80004256 <log_write>
        brelse(bp);
    800031aa:	854a                	mv	a0,s2
    800031ac:	00000097          	auipc	ra,0x0
    800031b0:	e20080e7          	jalr	-480(ra) # 80002fcc <brelse>
  bp = bread(dev, bno);
    800031b4:	85a6                	mv	a1,s1
    800031b6:	855e                	mv	a0,s7
    800031b8:	00000097          	auipc	ra,0x0
    800031bc:	ce4080e7          	jalr	-796(ra) # 80002e9c <bread>
    800031c0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031c2:	40000613          	li	a2,1024
    800031c6:	4581                	li	a1,0
    800031c8:	05850513          	addi	a0,a0,88
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	b06080e7          	jalr	-1274(ra) # 80000cd2 <memset>
  log_write(bp);
    800031d4:	854a                	mv	a0,s2
    800031d6:	00001097          	auipc	ra,0x1
    800031da:	080080e7          	jalr	128(ra) # 80004256 <log_write>
  brelse(bp);
    800031de:	854a                	mv	a0,s2
    800031e0:	00000097          	auipc	ra,0x0
    800031e4:	dec080e7          	jalr	-532(ra) # 80002fcc <brelse>
}
    800031e8:	8526                	mv	a0,s1
    800031ea:	60e6                	ld	ra,88(sp)
    800031ec:	6446                	ld	s0,80(sp)
    800031ee:	64a6                	ld	s1,72(sp)
    800031f0:	6906                	ld	s2,64(sp)
    800031f2:	79e2                	ld	s3,56(sp)
    800031f4:	7a42                	ld	s4,48(sp)
    800031f6:	7aa2                	ld	s5,40(sp)
    800031f8:	7b02                	ld	s6,32(sp)
    800031fa:	6be2                	ld	s7,24(sp)
    800031fc:	6c42                	ld	s8,16(sp)
    800031fe:	6ca2                	ld	s9,8(sp)
    80003200:	6125                	addi	sp,sp,96
    80003202:	8082                	ret
    brelse(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	dc6080e7          	jalr	-570(ra) # 80002fcc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000320e:	015c87bb          	addw	a5,s9,s5
    80003212:	00078a9b          	sext.w	s5,a5
    80003216:	004b2703          	lw	a4,4(s6)
    8000321a:	06eaf163          	bgeu	s5,a4,8000327c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000321e:	41fad79b          	sraiw	a5,s5,0x1f
    80003222:	0137d79b          	srliw	a5,a5,0x13
    80003226:	015787bb          	addw	a5,a5,s5
    8000322a:	40d7d79b          	sraiw	a5,a5,0xd
    8000322e:	01cb2583          	lw	a1,28(s6)
    80003232:	9dbd                	addw	a1,a1,a5
    80003234:	855e                	mv	a0,s7
    80003236:	00000097          	auipc	ra,0x0
    8000323a:	c66080e7          	jalr	-922(ra) # 80002e9c <bread>
    8000323e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003240:	004b2503          	lw	a0,4(s6)
    80003244:	000a849b          	sext.w	s1,s5
    80003248:	8762                	mv	a4,s8
    8000324a:	faa4fde3          	bgeu	s1,a0,80003204 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000324e:	00777693          	andi	a3,a4,7
    80003252:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003256:	41f7579b          	sraiw	a5,a4,0x1f
    8000325a:	01d7d79b          	srliw	a5,a5,0x1d
    8000325e:	9fb9                	addw	a5,a5,a4
    80003260:	4037d79b          	sraiw	a5,a5,0x3
    80003264:	00f90633          	add	a2,s2,a5
    80003268:	05864603          	lbu	a2,88(a2)
    8000326c:	00c6f5b3          	and	a1,a3,a2
    80003270:	d585                	beqz	a1,80003198 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003272:	2705                	addiw	a4,a4,1
    80003274:	2485                	addiw	s1,s1,1
    80003276:	fd471ae3          	bne	a4,s4,8000324a <balloc+0xec>
    8000327a:	b769                	j	80003204 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000327c:	00005517          	auipc	a0,0x5
    80003280:	2f450513          	addi	a0,a0,756 # 80008570 <syscalls+0x108>
    80003284:	ffffd097          	auipc	ra,0xffffd
    80003288:	306080e7          	jalr	774(ra) # 8000058a <printf>
  return 0;
    8000328c:	4481                	li	s1,0
    8000328e:	bfa9                	j	800031e8 <balloc+0x8a>

0000000080003290 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003290:	7179                	addi	sp,sp,-48
    80003292:	f406                	sd	ra,40(sp)
    80003294:	f022                	sd	s0,32(sp)
    80003296:	ec26                	sd	s1,24(sp)
    80003298:	e84a                	sd	s2,16(sp)
    8000329a:	e44e                	sd	s3,8(sp)
    8000329c:	e052                	sd	s4,0(sp)
    8000329e:	1800                	addi	s0,sp,48
    800032a0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032a2:	47ad                	li	a5,11
    800032a4:	02b7e863          	bltu	a5,a1,800032d4 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800032a8:	02059793          	slli	a5,a1,0x20
    800032ac:	01e7d593          	srli	a1,a5,0x1e
    800032b0:	00b504b3          	add	s1,a0,a1
    800032b4:	0504a903          	lw	s2,80(s1)
    800032b8:	06091e63          	bnez	s2,80003334 <bmap+0xa4>
      addr = balloc(ip->dev);
    800032bc:	4108                	lw	a0,0(a0)
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	ea0080e7          	jalr	-352(ra) # 8000315e <balloc>
    800032c6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032ca:	06090563          	beqz	s2,80003334 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800032ce:	0524a823          	sw	s2,80(s1)
    800032d2:	a08d                	j	80003334 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800032d4:	ff45849b          	addiw	s1,a1,-12
    800032d8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032dc:	0ff00793          	li	a5,255
    800032e0:	08e7e563          	bltu	a5,a4,8000336a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800032e4:	08052903          	lw	s2,128(a0)
    800032e8:	00091d63          	bnez	s2,80003302 <bmap+0x72>
      addr = balloc(ip->dev);
    800032ec:	4108                	lw	a0,0(a0)
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	e70080e7          	jalr	-400(ra) # 8000315e <balloc>
    800032f6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800032fa:	02090d63          	beqz	s2,80003334 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800032fe:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003302:	85ca                	mv	a1,s2
    80003304:	0009a503          	lw	a0,0(s3)
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	b94080e7          	jalr	-1132(ra) # 80002e9c <bread>
    80003310:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003312:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003316:	02049713          	slli	a4,s1,0x20
    8000331a:	01e75593          	srli	a1,a4,0x1e
    8000331e:	00b784b3          	add	s1,a5,a1
    80003322:	0004a903          	lw	s2,0(s1)
    80003326:	02090063          	beqz	s2,80003346 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000332a:	8552                	mv	a0,s4
    8000332c:	00000097          	auipc	ra,0x0
    80003330:	ca0080e7          	jalr	-864(ra) # 80002fcc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003334:	854a                	mv	a0,s2
    80003336:	70a2                	ld	ra,40(sp)
    80003338:	7402                	ld	s0,32(sp)
    8000333a:	64e2                	ld	s1,24(sp)
    8000333c:	6942                	ld	s2,16(sp)
    8000333e:	69a2                	ld	s3,8(sp)
    80003340:	6a02                	ld	s4,0(sp)
    80003342:	6145                	addi	sp,sp,48
    80003344:	8082                	ret
      addr = balloc(ip->dev);
    80003346:	0009a503          	lw	a0,0(s3)
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	e14080e7          	jalr	-492(ra) # 8000315e <balloc>
    80003352:	0005091b          	sext.w	s2,a0
      if(addr){
    80003356:	fc090ae3          	beqz	s2,8000332a <bmap+0x9a>
        a[bn] = addr;
    8000335a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000335e:	8552                	mv	a0,s4
    80003360:	00001097          	auipc	ra,0x1
    80003364:	ef6080e7          	jalr	-266(ra) # 80004256 <log_write>
    80003368:	b7c9                	j	8000332a <bmap+0x9a>
  panic("bmap: out of range");
    8000336a:	00005517          	auipc	a0,0x5
    8000336e:	21e50513          	addi	a0,a0,542 # 80008588 <syscalls+0x120>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	1ce080e7          	jalr	462(ra) # 80000540 <panic>

000000008000337a <iget>:
{
    8000337a:	7179                	addi	sp,sp,-48
    8000337c:	f406                	sd	ra,40(sp)
    8000337e:	f022                	sd	s0,32(sp)
    80003380:	ec26                	sd	s1,24(sp)
    80003382:	e84a                	sd	s2,16(sp)
    80003384:	e44e                	sd	s3,8(sp)
    80003386:	e052                	sd	s4,0(sp)
    80003388:	1800                	addi	s0,sp,48
    8000338a:	89aa                	mv	s3,a0
    8000338c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000338e:	0001c517          	auipc	a0,0x1c
    80003392:	d0a50513          	addi	a0,a0,-758 # 8001f098 <itable>
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	840080e7          	jalr	-1984(ra) # 80000bd6 <acquire>
  empty = 0;
    8000339e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033a0:	0001c497          	auipc	s1,0x1c
    800033a4:	d1048493          	addi	s1,s1,-752 # 8001f0b0 <itable+0x18>
    800033a8:	0001d697          	auipc	a3,0x1d
    800033ac:	79868693          	addi	a3,a3,1944 # 80020b40 <log>
    800033b0:	a039                	j	800033be <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033b2:	02090b63          	beqz	s2,800033e8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800033b6:	08848493          	addi	s1,s1,136
    800033ba:	02d48a63          	beq	s1,a3,800033ee <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033be:	449c                	lw	a5,8(s1)
    800033c0:	fef059e3          	blez	a5,800033b2 <iget+0x38>
    800033c4:	4098                	lw	a4,0(s1)
    800033c6:	ff3716e3          	bne	a4,s3,800033b2 <iget+0x38>
    800033ca:	40d8                	lw	a4,4(s1)
    800033cc:	ff4713e3          	bne	a4,s4,800033b2 <iget+0x38>
      ip->ref++;
    800033d0:	2785                	addiw	a5,a5,1
    800033d2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800033d4:	0001c517          	auipc	a0,0x1c
    800033d8:	cc450513          	addi	a0,a0,-828 # 8001f098 <itable>
    800033dc:	ffffe097          	auipc	ra,0xffffe
    800033e0:	8ae080e7          	jalr	-1874(ra) # 80000c8a <release>
      return ip;
    800033e4:	8926                	mv	s2,s1
    800033e6:	a03d                	j	80003414 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033e8:	f7f9                	bnez	a5,800033b6 <iget+0x3c>
    800033ea:	8926                	mv	s2,s1
    800033ec:	b7e9                	j	800033b6 <iget+0x3c>
  if(empty == 0)
    800033ee:	02090c63          	beqz	s2,80003426 <iget+0xac>
  ip->dev = dev;
    800033f2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033f6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800033fa:	4785                	li	a5,1
    800033fc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003400:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003404:	0001c517          	auipc	a0,0x1c
    80003408:	c9450513          	addi	a0,a0,-876 # 8001f098 <itable>
    8000340c:	ffffe097          	auipc	ra,0xffffe
    80003410:	87e080e7          	jalr	-1922(ra) # 80000c8a <release>
}
    80003414:	854a                	mv	a0,s2
    80003416:	70a2                	ld	ra,40(sp)
    80003418:	7402                	ld	s0,32(sp)
    8000341a:	64e2                	ld	s1,24(sp)
    8000341c:	6942                	ld	s2,16(sp)
    8000341e:	69a2                	ld	s3,8(sp)
    80003420:	6a02                	ld	s4,0(sp)
    80003422:	6145                	addi	sp,sp,48
    80003424:	8082                	ret
    panic("iget: no inodes");
    80003426:	00005517          	auipc	a0,0x5
    8000342a:	17a50513          	addi	a0,a0,378 # 800085a0 <syscalls+0x138>
    8000342e:	ffffd097          	auipc	ra,0xffffd
    80003432:	112080e7          	jalr	274(ra) # 80000540 <panic>

0000000080003436 <fsinit>:
fsinit(int dev) {
    80003436:	7179                	addi	sp,sp,-48
    80003438:	f406                	sd	ra,40(sp)
    8000343a:	f022                	sd	s0,32(sp)
    8000343c:	ec26                	sd	s1,24(sp)
    8000343e:	e84a                	sd	s2,16(sp)
    80003440:	e44e                	sd	s3,8(sp)
    80003442:	1800                	addi	s0,sp,48
    80003444:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003446:	4585                	li	a1,1
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	a54080e7          	jalr	-1452(ra) # 80002e9c <bread>
    80003450:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003452:	0001c997          	auipc	s3,0x1c
    80003456:	c2698993          	addi	s3,s3,-986 # 8001f078 <sb>
    8000345a:	02000613          	li	a2,32
    8000345e:	05850593          	addi	a1,a0,88
    80003462:	854e                	mv	a0,s3
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	8ca080e7          	jalr	-1846(ra) # 80000d2e <memmove>
  brelse(bp);
    8000346c:	8526                	mv	a0,s1
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	b5e080e7          	jalr	-1186(ra) # 80002fcc <brelse>
  if(sb.magic != FSMAGIC)
    80003476:	0009a703          	lw	a4,0(s3)
    8000347a:	102037b7          	lui	a5,0x10203
    8000347e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003482:	02f71263          	bne	a4,a5,800034a6 <fsinit+0x70>
  initlog(dev, &sb);
    80003486:	0001c597          	auipc	a1,0x1c
    8000348a:	bf258593          	addi	a1,a1,-1038 # 8001f078 <sb>
    8000348e:	854a                	mv	a0,s2
    80003490:	00001097          	auipc	ra,0x1
    80003494:	b4a080e7          	jalr	-1206(ra) # 80003fda <initlog>
}
    80003498:	70a2                	ld	ra,40(sp)
    8000349a:	7402                	ld	s0,32(sp)
    8000349c:	64e2                	ld	s1,24(sp)
    8000349e:	6942                	ld	s2,16(sp)
    800034a0:	69a2                	ld	s3,8(sp)
    800034a2:	6145                	addi	sp,sp,48
    800034a4:	8082                	ret
    panic("invalid file system");
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	10a50513          	addi	a0,a0,266 # 800085b0 <syscalls+0x148>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	092080e7          	jalr	146(ra) # 80000540 <panic>

00000000800034b6 <iinit>:
{
    800034b6:	7179                	addi	sp,sp,-48
    800034b8:	f406                	sd	ra,40(sp)
    800034ba:	f022                	sd	s0,32(sp)
    800034bc:	ec26                	sd	s1,24(sp)
    800034be:	e84a                	sd	s2,16(sp)
    800034c0:	e44e                	sd	s3,8(sp)
    800034c2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800034c4:	00005597          	auipc	a1,0x5
    800034c8:	10458593          	addi	a1,a1,260 # 800085c8 <syscalls+0x160>
    800034cc:	0001c517          	auipc	a0,0x1c
    800034d0:	bcc50513          	addi	a0,a0,-1076 # 8001f098 <itable>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	672080e7          	jalr	1650(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034dc:	0001c497          	auipc	s1,0x1c
    800034e0:	be448493          	addi	s1,s1,-1052 # 8001f0c0 <itable+0x28>
    800034e4:	0001d997          	auipc	s3,0x1d
    800034e8:	66c98993          	addi	s3,s3,1644 # 80020b50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800034ec:	00005917          	auipc	s2,0x5
    800034f0:	0e490913          	addi	s2,s2,228 # 800085d0 <syscalls+0x168>
    800034f4:	85ca                	mv	a1,s2
    800034f6:	8526                	mv	a0,s1
    800034f8:	00001097          	auipc	ra,0x1
    800034fc:	e42080e7          	jalr	-446(ra) # 8000433a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003500:	08848493          	addi	s1,s1,136
    80003504:	ff3498e3          	bne	s1,s3,800034f4 <iinit+0x3e>
}
    80003508:	70a2                	ld	ra,40(sp)
    8000350a:	7402                	ld	s0,32(sp)
    8000350c:	64e2                	ld	s1,24(sp)
    8000350e:	6942                	ld	s2,16(sp)
    80003510:	69a2                	ld	s3,8(sp)
    80003512:	6145                	addi	sp,sp,48
    80003514:	8082                	ret

0000000080003516 <ialloc>:
{
    80003516:	715d                	addi	sp,sp,-80
    80003518:	e486                	sd	ra,72(sp)
    8000351a:	e0a2                	sd	s0,64(sp)
    8000351c:	fc26                	sd	s1,56(sp)
    8000351e:	f84a                	sd	s2,48(sp)
    80003520:	f44e                	sd	s3,40(sp)
    80003522:	f052                	sd	s4,32(sp)
    80003524:	ec56                	sd	s5,24(sp)
    80003526:	e85a                	sd	s6,16(sp)
    80003528:	e45e                	sd	s7,8(sp)
    8000352a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000352c:	0001c717          	auipc	a4,0x1c
    80003530:	b5872703          	lw	a4,-1192(a4) # 8001f084 <sb+0xc>
    80003534:	4785                	li	a5,1
    80003536:	04e7fa63          	bgeu	a5,a4,8000358a <ialloc+0x74>
    8000353a:	8aaa                	mv	s5,a0
    8000353c:	8bae                	mv	s7,a1
    8000353e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003540:	0001ca17          	auipc	s4,0x1c
    80003544:	b38a0a13          	addi	s4,s4,-1224 # 8001f078 <sb>
    80003548:	00048b1b          	sext.w	s6,s1
    8000354c:	0044d593          	srli	a1,s1,0x4
    80003550:	018a2783          	lw	a5,24(s4)
    80003554:	9dbd                	addw	a1,a1,a5
    80003556:	8556                	mv	a0,s5
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	944080e7          	jalr	-1724(ra) # 80002e9c <bread>
    80003560:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003562:	05850993          	addi	s3,a0,88
    80003566:	00f4f793          	andi	a5,s1,15
    8000356a:	079a                	slli	a5,a5,0x6
    8000356c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000356e:	00099783          	lh	a5,0(s3)
    80003572:	c3a1                	beqz	a5,800035b2 <ialloc+0x9c>
    brelse(bp);
    80003574:	00000097          	auipc	ra,0x0
    80003578:	a58080e7          	jalr	-1448(ra) # 80002fcc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000357c:	0485                	addi	s1,s1,1
    8000357e:	00ca2703          	lw	a4,12(s4)
    80003582:	0004879b          	sext.w	a5,s1
    80003586:	fce7e1e3          	bltu	a5,a4,80003548 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000358a:	00005517          	auipc	a0,0x5
    8000358e:	04e50513          	addi	a0,a0,78 # 800085d8 <syscalls+0x170>
    80003592:	ffffd097          	auipc	ra,0xffffd
    80003596:	ff8080e7          	jalr	-8(ra) # 8000058a <printf>
  return 0;
    8000359a:	4501                	li	a0,0
}
    8000359c:	60a6                	ld	ra,72(sp)
    8000359e:	6406                	ld	s0,64(sp)
    800035a0:	74e2                	ld	s1,56(sp)
    800035a2:	7942                	ld	s2,48(sp)
    800035a4:	79a2                	ld	s3,40(sp)
    800035a6:	7a02                	ld	s4,32(sp)
    800035a8:	6ae2                	ld	s5,24(sp)
    800035aa:	6b42                	ld	s6,16(sp)
    800035ac:	6ba2                	ld	s7,8(sp)
    800035ae:	6161                	addi	sp,sp,80
    800035b0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800035b2:	04000613          	li	a2,64
    800035b6:	4581                	li	a1,0
    800035b8:	854e                	mv	a0,s3
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	718080e7          	jalr	1816(ra) # 80000cd2 <memset>
      dip->type = type;
    800035c2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035c6:	854a                	mv	a0,s2
    800035c8:	00001097          	auipc	ra,0x1
    800035cc:	c8e080e7          	jalr	-882(ra) # 80004256 <log_write>
      brelse(bp);
    800035d0:	854a                	mv	a0,s2
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	9fa080e7          	jalr	-1542(ra) # 80002fcc <brelse>
      return iget(dev, inum);
    800035da:	85da                	mv	a1,s6
    800035dc:	8556                	mv	a0,s5
    800035de:	00000097          	auipc	ra,0x0
    800035e2:	d9c080e7          	jalr	-612(ra) # 8000337a <iget>
    800035e6:	bf5d                	j	8000359c <ialloc+0x86>

00000000800035e8 <iupdate>:
{
    800035e8:	1101                	addi	sp,sp,-32
    800035ea:	ec06                	sd	ra,24(sp)
    800035ec:	e822                	sd	s0,16(sp)
    800035ee:	e426                	sd	s1,8(sp)
    800035f0:	e04a                	sd	s2,0(sp)
    800035f2:	1000                	addi	s0,sp,32
    800035f4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035f6:	415c                	lw	a5,4(a0)
    800035f8:	0047d79b          	srliw	a5,a5,0x4
    800035fc:	0001c597          	auipc	a1,0x1c
    80003600:	a945a583          	lw	a1,-1388(a1) # 8001f090 <sb+0x18>
    80003604:	9dbd                	addw	a1,a1,a5
    80003606:	4108                	lw	a0,0(a0)
    80003608:	00000097          	auipc	ra,0x0
    8000360c:	894080e7          	jalr	-1900(ra) # 80002e9c <bread>
    80003610:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003612:	05850793          	addi	a5,a0,88
    80003616:	40d8                	lw	a4,4(s1)
    80003618:	8b3d                	andi	a4,a4,15
    8000361a:	071a                	slli	a4,a4,0x6
    8000361c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000361e:	04449703          	lh	a4,68(s1)
    80003622:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003626:	04649703          	lh	a4,70(s1)
    8000362a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000362e:	04849703          	lh	a4,72(s1)
    80003632:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003636:	04a49703          	lh	a4,74(s1)
    8000363a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000363e:	44f8                	lw	a4,76(s1)
    80003640:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003642:	03400613          	li	a2,52
    80003646:	05048593          	addi	a1,s1,80
    8000364a:	00c78513          	addi	a0,a5,12
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	6e0080e7          	jalr	1760(ra) # 80000d2e <memmove>
  log_write(bp);
    80003656:	854a                	mv	a0,s2
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	bfe080e7          	jalr	-1026(ra) # 80004256 <log_write>
  brelse(bp);
    80003660:	854a                	mv	a0,s2
    80003662:	00000097          	auipc	ra,0x0
    80003666:	96a080e7          	jalr	-1686(ra) # 80002fcc <brelse>
}
    8000366a:	60e2                	ld	ra,24(sp)
    8000366c:	6442                	ld	s0,16(sp)
    8000366e:	64a2                	ld	s1,8(sp)
    80003670:	6902                	ld	s2,0(sp)
    80003672:	6105                	addi	sp,sp,32
    80003674:	8082                	ret

0000000080003676 <idup>:
{
    80003676:	1101                	addi	sp,sp,-32
    80003678:	ec06                	sd	ra,24(sp)
    8000367a:	e822                	sd	s0,16(sp)
    8000367c:	e426                	sd	s1,8(sp)
    8000367e:	1000                	addi	s0,sp,32
    80003680:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003682:	0001c517          	auipc	a0,0x1c
    80003686:	a1650513          	addi	a0,a0,-1514 # 8001f098 <itable>
    8000368a:	ffffd097          	auipc	ra,0xffffd
    8000368e:	54c080e7          	jalr	1356(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003692:	449c                	lw	a5,8(s1)
    80003694:	2785                	addiw	a5,a5,1
    80003696:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003698:	0001c517          	auipc	a0,0x1c
    8000369c:	a0050513          	addi	a0,a0,-1536 # 8001f098 <itable>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	5ea080e7          	jalr	1514(ra) # 80000c8a <release>
}
    800036a8:	8526                	mv	a0,s1
    800036aa:	60e2                	ld	ra,24(sp)
    800036ac:	6442                	ld	s0,16(sp)
    800036ae:	64a2                	ld	s1,8(sp)
    800036b0:	6105                	addi	sp,sp,32
    800036b2:	8082                	ret

00000000800036b4 <ilock>:
{
    800036b4:	1101                	addi	sp,sp,-32
    800036b6:	ec06                	sd	ra,24(sp)
    800036b8:	e822                	sd	s0,16(sp)
    800036ba:	e426                	sd	s1,8(sp)
    800036bc:	e04a                	sd	s2,0(sp)
    800036be:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036c0:	c115                	beqz	a0,800036e4 <ilock+0x30>
    800036c2:	84aa                	mv	s1,a0
    800036c4:	451c                	lw	a5,8(a0)
    800036c6:	00f05f63          	blez	a5,800036e4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036ca:	0541                	addi	a0,a0,16
    800036cc:	00001097          	auipc	ra,0x1
    800036d0:	ca8080e7          	jalr	-856(ra) # 80004374 <acquiresleep>
  if(ip->valid == 0){
    800036d4:	40bc                	lw	a5,64(s1)
    800036d6:	cf99                	beqz	a5,800036f4 <ilock+0x40>
}
    800036d8:	60e2                	ld	ra,24(sp)
    800036da:	6442                	ld	s0,16(sp)
    800036dc:	64a2                	ld	s1,8(sp)
    800036de:	6902                	ld	s2,0(sp)
    800036e0:	6105                	addi	sp,sp,32
    800036e2:	8082                	ret
    panic("ilock");
    800036e4:	00005517          	auipc	a0,0x5
    800036e8:	f0c50513          	addi	a0,a0,-244 # 800085f0 <syscalls+0x188>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	e54080e7          	jalr	-428(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f4:	40dc                	lw	a5,4(s1)
    800036f6:	0047d79b          	srliw	a5,a5,0x4
    800036fa:	0001c597          	auipc	a1,0x1c
    800036fe:	9965a583          	lw	a1,-1642(a1) # 8001f090 <sb+0x18>
    80003702:	9dbd                	addw	a1,a1,a5
    80003704:	4088                	lw	a0,0(s1)
    80003706:	fffff097          	auipc	ra,0xfffff
    8000370a:	796080e7          	jalr	1942(ra) # 80002e9c <bread>
    8000370e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003710:	05850593          	addi	a1,a0,88
    80003714:	40dc                	lw	a5,4(s1)
    80003716:	8bbd                	andi	a5,a5,15
    80003718:	079a                	slli	a5,a5,0x6
    8000371a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000371c:	00059783          	lh	a5,0(a1)
    80003720:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003724:	00259783          	lh	a5,2(a1)
    80003728:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000372c:	00459783          	lh	a5,4(a1)
    80003730:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003734:	00659783          	lh	a5,6(a1)
    80003738:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000373c:	459c                	lw	a5,8(a1)
    8000373e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003740:	03400613          	li	a2,52
    80003744:	05b1                	addi	a1,a1,12
    80003746:	05048513          	addi	a0,s1,80
    8000374a:	ffffd097          	auipc	ra,0xffffd
    8000374e:	5e4080e7          	jalr	1508(ra) # 80000d2e <memmove>
    brelse(bp);
    80003752:	854a                	mv	a0,s2
    80003754:	00000097          	auipc	ra,0x0
    80003758:	878080e7          	jalr	-1928(ra) # 80002fcc <brelse>
    ip->valid = 1;
    8000375c:	4785                	li	a5,1
    8000375e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003760:	04449783          	lh	a5,68(s1)
    80003764:	fbb5                	bnez	a5,800036d8 <ilock+0x24>
      panic("ilock: no type");
    80003766:	00005517          	auipc	a0,0x5
    8000376a:	e9250513          	addi	a0,a0,-366 # 800085f8 <syscalls+0x190>
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	dd2080e7          	jalr	-558(ra) # 80000540 <panic>

0000000080003776 <iunlock>:
{
    80003776:	1101                	addi	sp,sp,-32
    80003778:	ec06                	sd	ra,24(sp)
    8000377a:	e822                	sd	s0,16(sp)
    8000377c:	e426                	sd	s1,8(sp)
    8000377e:	e04a                	sd	s2,0(sp)
    80003780:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003782:	c905                	beqz	a0,800037b2 <iunlock+0x3c>
    80003784:	84aa                	mv	s1,a0
    80003786:	01050913          	addi	s2,a0,16
    8000378a:	854a                	mv	a0,s2
    8000378c:	00001097          	auipc	ra,0x1
    80003790:	c82080e7          	jalr	-894(ra) # 8000440e <holdingsleep>
    80003794:	cd19                	beqz	a0,800037b2 <iunlock+0x3c>
    80003796:	449c                	lw	a5,8(s1)
    80003798:	00f05d63          	blez	a5,800037b2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	c2c080e7          	jalr	-980(ra) # 800043ca <releasesleep>
}
    800037a6:	60e2                	ld	ra,24(sp)
    800037a8:	6442                	ld	s0,16(sp)
    800037aa:	64a2                	ld	s1,8(sp)
    800037ac:	6902                	ld	s2,0(sp)
    800037ae:	6105                	addi	sp,sp,32
    800037b0:	8082                	ret
    panic("iunlock");
    800037b2:	00005517          	auipc	a0,0x5
    800037b6:	e5650513          	addi	a0,a0,-426 # 80008608 <syscalls+0x1a0>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	d86080e7          	jalr	-634(ra) # 80000540 <panic>

00000000800037c2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037c2:	7179                	addi	sp,sp,-48
    800037c4:	f406                	sd	ra,40(sp)
    800037c6:	f022                	sd	s0,32(sp)
    800037c8:	ec26                	sd	s1,24(sp)
    800037ca:	e84a                	sd	s2,16(sp)
    800037cc:	e44e                	sd	s3,8(sp)
    800037ce:	e052                	sd	s4,0(sp)
    800037d0:	1800                	addi	s0,sp,48
    800037d2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037d4:	05050493          	addi	s1,a0,80
    800037d8:	08050913          	addi	s2,a0,128
    800037dc:	a021                	j	800037e4 <itrunc+0x22>
    800037de:	0491                	addi	s1,s1,4
    800037e0:	01248d63          	beq	s1,s2,800037fa <itrunc+0x38>
    if(ip->addrs[i]){
    800037e4:	408c                	lw	a1,0(s1)
    800037e6:	dde5                	beqz	a1,800037de <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037e8:	0009a503          	lw	a0,0(s3)
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	8f6080e7          	jalr	-1802(ra) # 800030e2 <bfree>
      ip->addrs[i] = 0;
    800037f4:	0004a023          	sw	zero,0(s1)
    800037f8:	b7dd                	j	800037de <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800037fa:	0809a583          	lw	a1,128(s3)
    800037fe:	e185                	bnez	a1,8000381e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003800:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003804:	854e                	mv	a0,s3
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	de2080e7          	jalr	-542(ra) # 800035e8 <iupdate>
}
    8000380e:	70a2                	ld	ra,40(sp)
    80003810:	7402                	ld	s0,32(sp)
    80003812:	64e2                	ld	s1,24(sp)
    80003814:	6942                	ld	s2,16(sp)
    80003816:	69a2                	ld	s3,8(sp)
    80003818:	6a02                	ld	s4,0(sp)
    8000381a:	6145                	addi	sp,sp,48
    8000381c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000381e:	0009a503          	lw	a0,0(s3)
    80003822:	fffff097          	auipc	ra,0xfffff
    80003826:	67a080e7          	jalr	1658(ra) # 80002e9c <bread>
    8000382a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000382c:	05850493          	addi	s1,a0,88
    80003830:	45850913          	addi	s2,a0,1112
    80003834:	a021                	j	8000383c <itrunc+0x7a>
    80003836:	0491                	addi	s1,s1,4
    80003838:	01248b63          	beq	s1,s2,8000384e <itrunc+0x8c>
      if(a[j])
    8000383c:	408c                	lw	a1,0(s1)
    8000383e:	dde5                	beqz	a1,80003836 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003840:	0009a503          	lw	a0,0(s3)
    80003844:	00000097          	auipc	ra,0x0
    80003848:	89e080e7          	jalr	-1890(ra) # 800030e2 <bfree>
    8000384c:	b7ed                	j	80003836 <itrunc+0x74>
    brelse(bp);
    8000384e:	8552                	mv	a0,s4
    80003850:	fffff097          	auipc	ra,0xfffff
    80003854:	77c080e7          	jalr	1916(ra) # 80002fcc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003858:	0809a583          	lw	a1,128(s3)
    8000385c:	0009a503          	lw	a0,0(s3)
    80003860:	00000097          	auipc	ra,0x0
    80003864:	882080e7          	jalr	-1918(ra) # 800030e2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003868:	0809a023          	sw	zero,128(s3)
    8000386c:	bf51                	j	80003800 <itrunc+0x3e>

000000008000386e <iput>:
{
    8000386e:	1101                	addi	sp,sp,-32
    80003870:	ec06                	sd	ra,24(sp)
    80003872:	e822                	sd	s0,16(sp)
    80003874:	e426                	sd	s1,8(sp)
    80003876:	e04a                	sd	s2,0(sp)
    80003878:	1000                	addi	s0,sp,32
    8000387a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000387c:	0001c517          	auipc	a0,0x1c
    80003880:	81c50513          	addi	a0,a0,-2020 # 8001f098 <itable>
    80003884:	ffffd097          	auipc	ra,0xffffd
    80003888:	352080e7          	jalr	850(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000388c:	4498                	lw	a4,8(s1)
    8000388e:	4785                	li	a5,1
    80003890:	02f70363          	beq	a4,a5,800038b6 <iput+0x48>
  ip->ref--;
    80003894:	449c                	lw	a5,8(s1)
    80003896:	37fd                	addiw	a5,a5,-1
    80003898:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000389a:	0001b517          	auipc	a0,0x1b
    8000389e:	7fe50513          	addi	a0,a0,2046 # 8001f098 <itable>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	3e8080e7          	jalr	1000(ra) # 80000c8a <release>
}
    800038aa:	60e2                	ld	ra,24(sp)
    800038ac:	6442                	ld	s0,16(sp)
    800038ae:	64a2                	ld	s1,8(sp)
    800038b0:	6902                	ld	s2,0(sp)
    800038b2:	6105                	addi	sp,sp,32
    800038b4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038b6:	40bc                	lw	a5,64(s1)
    800038b8:	dff1                	beqz	a5,80003894 <iput+0x26>
    800038ba:	04a49783          	lh	a5,74(s1)
    800038be:	fbf9                	bnez	a5,80003894 <iput+0x26>
    acquiresleep(&ip->lock);
    800038c0:	01048913          	addi	s2,s1,16
    800038c4:	854a                	mv	a0,s2
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	aae080e7          	jalr	-1362(ra) # 80004374 <acquiresleep>
    release(&itable.lock);
    800038ce:	0001b517          	auipc	a0,0x1b
    800038d2:	7ca50513          	addi	a0,a0,1994 # 8001f098 <itable>
    800038d6:	ffffd097          	auipc	ra,0xffffd
    800038da:	3b4080e7          	jalr	948(ra) # 80000c8a <release>
    itrunc(ip);
    800038de:	8526                	mv	a0,s1
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	ee2080e7          	jalr	-286(ra) # 800037c2 <itrunc>
    ip->type = 0;
    800038e8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038ec:	8526                	mv	a0,s1
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	cfa080e7          	jalr	-774(ra) # 800035e8 <iupdate>
    ip->valid = 0;
    800038f6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800038fa:	854a                	mv	a0,s2
    800038fc:	00001097          	auipc	ra,0x1
    80003900:	ace080e7          	jalr	-1330(ra) # 800043ca <releasesleep>
    acquire(&itable.lock);
    80003904:	0001b517          	auipc	a0,0x1b
    80003908:	79450513          	addi	a0,a0,1940 # 8001f098 <itable>
    8000390c:	ffffd097          	auipc	ra,0xffffd
    80003910:	2ca080e7          	jalr	714(ra) # 80000bd6 <acquire>
    80003914:	b741                	j	80003894 <iput+0x26>

0000000080003916 <iunlockput>:
{
    80003916:	1101                	addi	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	1000                	addi	s0,sp,32
    80003920:	84aa                	mv	s1,a0
  iunlock(ip);
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e54080e7          	jalr	-428(ra) # 80003776 <iunlock>
  iput(ip);
    8000392a:	8526                	mv	a0,s1
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	f42080e7          	jalr	-190(ra) # 8000386e <iput>
}
    80003934:	60e2                	ld	ra,24(sp)
    80003936:	6442                	ld	s0,16(sp)
    80003938:	64a2                	ld	s1,8(sp)
    8000393a:	6105                	addi	sp,sp,32
    8000393c:	8082                	ret

000000008000393e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000393e:	1141                	addi	sp,sp,-16
    80003940:	e422                	sd	s0,8(sp)
    80003942:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003944:	411c                	lw	a5,0(a0)
    80003946:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003948:	415c                	lw	a5,4(a0)
    8000394a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000394c:	04451783          	lh	a5,68(a0)
    80003950:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003954:	04a51783          	lh	a5,74(a0)
    80003958:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000395c:	04c56783          	lwu	a5,76(a0)
    80003960:	e99c                	sd	a5,16(a1)
}
    80003962:	6422                	ld	s0,8(sp)
    80003964:	0141                	addi	sp,sp,16
    80003966:	8082                	ret

0000000080003968 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003968:	457c                	lw	a5,76(a0)
    8000396a:	0ed7e963          	bltu	a5,a3,80003a5c <readi+0xf4>
{
    8000396e:	7159                	addi	sp,sp,-112
    80003970:	f486                	sd	ra,104(sp)
    80003972:	f0a2                	sd	s0,96(sp)
    80003974:	eca6                	sd	s1,88(sp)
    80003976:	e8ca                	sd	s2,80(sp)
    80003978:	e4ce                	sd	s3,72(sp)
    8000397a:	e0d2                	sd	s4,64(sp)
    8000397c:	fc56                	sd	s5,56(sp)
    8000397e:	f85a                	sd	s6,48(sp)
    80003980:	f45e                	sd	s7,40(sp)
    80003982:	f062                	sd	s8,32(sp)
    80003984:	ec66                	sd	s9,24(sp)
    80003986:	e86a                	sd	s10,16(sp)
    80003988:	e46e                	sd	s11,8(sp)
    8000398a:	1880                	addi	s0,sp,112
    8000398c:	8b2a                	mv	s6,a0
    8000398e:	8bae                	mv	s7,a1
    80003990:	8a32                	mv	s4,a2
    80003992:	84b6                	mv	s1,a3
    80003994:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003996:	9f35                	addw	a4,a4,a3
    return 0;
    80003998:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000399a:	0ad76063          	bltu	a4,a3,80003a3a <readi+0xd2>
  if(off + n > ip->size)
    8000399e:	00e7f463          	bgeu	a5,a4,800039a6 <readi+0x3e>
    n = ip->size - off;
    800039a2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039a6:	0a0a8963          	beqz	s5,80003a58 <readi+0xf0>
    800039aa:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800039ac:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039b0:	5c7d                	li	s8,-1
    800039b2:	a82d                	j	800039ec <readi+0x84>
    800039b4:	020d1d93          	slli	s11,s10,0x20
    800039b8:	020ddd93          	srli	s11,s11,0x20
    800039bc:	05890613          	addi	a2,s2,88
    800039c0:	86ee                	mv	a3,s11
    800039c2:	963a                	add	a2,a2,a4
    800039c4:	85d2                	mv	a1,s4
    800039c6:	855e                	mv	a0,s7
    800039c8:	fffff097          	auipc	ra,0xfffff
    800039cc:	a94080e7          	jalr	-1388(ra) # 8000245c <either_copyout>
    800039d0:	05850d63          	beq	a0,s8,80003a2a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800039d4:	854a                	mv	a0,s2
    800039d6:	fffff097          	auipc	ra,0xfffff
    800039da:	5f6080e7          	jalr	1526(ra) # 80002fcc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039de:	013d09bb          	addw	s3,s10,s3
    800039e2:	009d04bb          	addw	s1,s10,s1
    800039e6:	9a6e                	add	s4,s4,s11
    800039e8:	0559f763          	bgeu	s3,s5,80003a36 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800039ec:	00a4d59b          	srliw	a1,s1,0xa
    800039f0:	855a                	mv	a0,s6
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	89e080e7          	jalr	-1890(ra) # 80003290 <bmap>
    800039fa:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800039fe:	cd85                	beqz	a1,80003a36 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a00:	000b2503          	lw	a0,0(s6)
    80003a04:	fffff097          	auipc	ra,0xfffff
    80003a08:	498080e7          	jalr	1176(ra) # 80002e9c <bread>
    80003a0c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a0e:	3ff4f713          	andi	a4,s1,1023
    80003a12:	40ec87bb          	subw	a5,s9,a4
    80003a16:	413a86bb          	subw	a3,s5,s3
    80003a1a:	8d3e                	mv	s10,a5
    80003a1c:	2781                	sext.w	a5,a5
    80003a1e:	0006861b          	sext.w	a2,a3
    80003a22:	f8f679e3          	bgeu	a2,a5,800039b4 <readi+0x4c>
    80003a26:	8d36                	mv	s10,a3
    80003a28:	b771                	j	800039b4 <readi+0x4c>
      brelse(bp);
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	fffff097          	auipc	ra,0xfffff
    80003a30:	5a0080e7          	jalr	1440(ra) # 80002fcc <brelse>
      tot = -1;
    80003a34:	59fd                	li	s3,-1
  }
  return tot;
    80003a36:	0009851b          	sext.w	a0,s3
}
    80003a3a:	70a6                	ld	ra,104(sp)
    80003a3c:	7406                	ld	s0,96(sp)
    80003a3e:	64e6                	ld	s1,88(sp)
    80003a40:	6946                	ld	s2,80(sp)
    80003a42:	69a6                	ld	s3,72(sp)
    80003a44:	6a06                	ld	s4,64(sp)
    80003a46:	7ae2                	ld	s5,56(sp)
    80003a48:	7b42                	ld	s6,48(sp)
    80003a4a:	7ba2                	ld	s7,40(sp)
    80003a4c:	7c02                	ld	s8,32(sp)
    80003a4e:	6ce2                	ld	s9,24(sp)
    80003a50:	6d42                	ld	s10,16(sp)
    80003a52:	6da2                	ld	s11,8(sp)
    80003a54:	6165                	addi	sp,sp,112
    80003a56:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a58:	89d6                	mv	s3,s5
    80003a5a:	bff1                	j	80003a36 <readi+0xce>
    return 0;
    80003a5c:	4501                	li	a0,0
}
    80003a5e:	8082                	ret

0000000080003a60 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a60:	457c                	lw	a5,76(a0)
    80003a62:	10d7e863          	bltu	a5,a3,80003b72 <writei+0x112>
{
    80003a66:	7159                	addi	sp,sp,-112
    80003a68:	f486                	sd	ra,104(sp)
    80003a6a:	f0a2                	sd	s0,96(sp)
    80003a6c:	eca6                	sd	s1,88(sp)
    80003a6e:	e8ca                	sd	s2,80(sp)
    80003a70:	e4ce                	sd	s3,72(sp)
    80003a72:	e0d2                	sd	s4,64(sp)
    80003a74:	fc56                	sd	s5,56(sp)
    80003a76:	f85a                	sd	s6,48(sp)
    80003a78:	f45e                	sd	s7,40(sp)
    80003a7a:	f062                	sd	s8,32(sp)
    80003a7c:	ec66                	sd	s9,24(sp)
    80003a7e:	e86a                	sd	s10,16(sp)
    80003a80:	e46e                	sd	s11,8(sp)
    80003a82:	1880                	addi	s0,sp,112
    80003a84:	8aaa                	mv	s5,a0
    80003a86:	8bae                	mv	s7,a1
    80003a88:	8a32                	mv	s4,a2
    80003a8a:	8936                	mv	s2,a3
    80003a8c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a8e:	00e687bb          	addw	a5,a3,a4
    80003a92:	0ed7e263          	bltu	a5,a3,80003b76 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a96:	00043737          	lui	a4,0x43
    80003a9a:	0ef76063          	bltu	a4,a5,80003b7a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a9e:	0c0b0863          	beqz	s6,80003b6e <writei+0x10e>
    80003aa2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003aa8:	5c7d                	li	s8,-1
    80003aaa:	a091                	j	80003aee <writei+0x8e>
    80003aac:	020d1d93          	slli	s11,s10,0x20
    80003ab0:	020ddd93          	srli	s11,s11,0x20
    80003ab4:	05848513          	addi	a0,s1,88
    80003ab8:	86ee                	mv	a3,s11
    80003aba:	8652                	mv	a2,s4
    80003abc:	85de                	mv	a1,s7
    80003abe:	953a                	add	a0,a0,a4
    80003ac0:	fffff097          	auipc	ra,0xfffff
    80003ac4:	9f2080e7          	jalr	-1550(ra) # 800024b2 <either_copyin>
    80003ac8:	07850263          	beq	a0,s8,80003b2c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003acc:	8526                	mv	a0,s1
    80003ace:	00000097          	auipc	ra,0x0
    80003ad2:	788080e7          	jalr	1928(ra) # 80004256 <log_write>
    brelse(bp);
    80003ad6:	8526                	mv	a0,s1
    80003ad8:	fffff097          	auipc	ra,0xfffff
    80003adc:	4f4080e7          	jalr	1268(ra) # 80002fcc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ae0:	013d09bb          	addw	s3,s10,s3
    80003ae4:	012d093b          	addw	s2,s10,s2
    80003ae8:	9a6e                	add	s4,s4,s11
    80003aea:	0569f663          	bgeu	s3,s6,80003b36 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003aee:	00a9559b          	srliw	a1,s2,0xa
    80003af2:	8556                	mv	a0,s5
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	79c080e7          	jalr	1948(ra) # 80003290 <bmap>
    80003afc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b00:	c99d                	beqz	a1,80003b36 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b02:	000aa503          	lw	a0,0(s5)
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	396080e7          	jalr	918(ra) # 80002e9c <bread>
    80003b0e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b10:	3ff97713          	andi	a4,s2,1023
    80003b14:	40ec87bb          	subw	a5,s9,a4
    80003b18:	413b06bb          	subw	a3,s6,s3
    80003b1c:	8d3e                	mv	s10,a5
    80003b1e:	2781                	sext.w	a5,a5
    80003b20:	0006861b          	sext.w	a2,a3
    80003b24:	f8f674e3          	bgeu	a2,a5,80003aac <writei+0x4c>
    80003b28:	8d36                	mv	s10,a3
    80003b2a:	b749                	j	80003aac <writei+0x4c>
      brelse(bp);
    80003b2c:	8526                	mv	a0,s1
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	49e080e7          	jalr	1182(ra) # 80002fcc <brelse>
  }

  if(off > ip->size)
    80003b36:	04caa783          	lw	a5,76(s5)
    80003b3a:	0127f463          	bgeu	a5,s2,80003b42 <writei+0xe2>
    ip->size = off;
    80003b3e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003b42:	8556                	mv	a0,s5
    80003b44:	00000097          	auipc	ra,0x0
    80003b48:	aa4080e7          	jalr	-1372(ra) # 800035e8 <iupdate>

  return tot;
    80003b4c:	0009851b          	sext.w	a0,s3
}
    80003b50:	70a6                	ld	ra,104(sp)
    80003b52:	7406                	ld	s0,96(sp)
    80003b54:	64e6                	ld	s1,88(sp)
    80003b56:	6946                	ld	s2,80(sp)
    80003b58:	69a6                	ld	s3,72(sp)
    80003b5a:	6a06                	ld	s4,64(sp)
    80003b5c:	7ae2                	ld	s5,56(sp)
    80003b5e:	7b42                	ld	s6,48(sp)
    80003b60:	7ba2                	ld	s7,40(sp)
    80003b62:	7c02                	ld	s8,32(sp)
    80003b64:	6ce2                	ld	s9,24(sp)
    80003b66:	6d42                	ld	s10,16(sp)
    80003b68:	6da2                	ld	s11,8(sp)
    80003b6a:	6165                	addi	sp,sp,112
    80003b6c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b6e:	89da                	mv	s3,s6
    80003b70:	bfc9                	j	80003b42 <writei+0xe2>
    return -1;
    80003b72:	557d                	li	a0,-1
}
    80003b74:	8082                	ret
    return -1;
    80003b76:	557d                	li	a0,-1
    80003b78:	bfe1                	j	80003b50 <writei+0xf0>
    return -1;
    80003b7a:	557d                	li	a0,-1
    80003b7c:	bfd1                	j	80003b50 <writei+0xf0>

0000000080003b7e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b7e:	1141                	addi	sp,sp,-16
    80003b80:	e406                	sd	ra,8(sp)
    80003b82:	e022                	sd	s0,0(sp)
    80003b84:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b86:	4639                	li	a2,14
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	21a080e7          	jalr	538(ra) # 80000da2 <strncmp>
}
    80003b90:	60a2                	ld	ra,8(sp)
    80003b92:	6402                	ld	s0,0(sp)
    80003b94:	0141                	addi	sp,sp,16
    80003b96:	8082                	ret

0000000080003b98 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b98:	7139                	addi	sp,sp,-64
    80003b9a:	fc06                	sd	ra,56(sp)
    80003b9c:	f822                	sd	s0,48(sp)
    80003b9e:	f426                	sd	s1,40(sp)
    80003ba0:	f04a                	sd	s2,32(sp)
    80003ba2:	ec4e                	sd	s3,24(sp)
    80003ba4:	e852                	sd	s4,16(sp)
    80003ba6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ba8:	04451703          	lh	a4,68(a0)
    80003bac:	4785                	li	a5,1
    80003bae:	00f71a63          	bne	a4,a5,80003bc2 <dirlookup+0x2a>
    80003bb2:	892a                	mv	s2,a0
    80003bb4:	89ae                	mv	s3,a1
    80003bb6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bb8:	457c                	lw	a5,76(a0)
    80003bba:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bbc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bbe:	e79d                	bnez	a5,80003bec <dirlookup+0x54>
    80003bc0:	a8a5                	j	80003c38 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bc2:	00005517          	auipc	a0,0x5
    80003bc6:	a4e50513          	addi	a0,a0,-1458 # 80008610 <syscalls+0x1a8>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	976080e7          	jalr	-1674(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003bd2:	00005517          	auipc	a0,0x5
    80003bd6:	a5650513          	addi	a0,a0,-1450 # 80008628 <syscalls+0x1c0>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	966080e7          	jalr	-1690(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003be2:	24c1                	addiw	s1,s1,16
    80003be4:	04c92783          	lw	a5,76(s2)
    80003be8:	04f4f763          	bgeu	s1,a5,80003c36 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bec:	4741                	li	a4,16
    80003bee:	86a6                	mv	a3,s1
    80003bf0:	fc040613          	addi	a2,s0,-64
    80003bf4:	4581                	li	a1,0
    80003bf6:	854a                	mv	a0,s2
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	d70080e7          	jalr	-656(ra) # 80003968 <readi>
    80003c00:	47c1                	li	a5,16
    80003c02:	fcf518e3          	bne	a0,a5,80003bd2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c06:	fc045783          	lhu	a5,-64(s0)
    80003c0a:	dfe1                	beqz	a5,80003be2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c0c:	fc240593          	addi	a1,s0,-62
    80003c10:	854e                	mv	a0,s3
    80003c12:	00000097          	auipc	ra,0x0
    80003c16:	f6c080e7          	jalr	-148(ra) # 80003b7e <namecmp>
    80003c1a:	f561                	bnez	a0,80003be2 <dirlookup+0x4a>
      if(poff)
    80003c1c:	000a0463          	beqz	s4,80003c24 <dirlookup+0x8c>
        *poff = off;
    80003c20:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c24:	fc045583          	lhu	a1,-64(s0)
    80003c28:	00092503          	lw	a0,0(s2)
    80003c2c:	fffff097          	auipc	ra,0xfffff
    80003c30:	74e080e7          	jalr	1870(ra) # 8000337a <iget>
    80003c34:	a011                	j	80003c38 <dirlookup+0xa0>
  return 0;
    80003c36:	4501                	li	a0,0
}
    80003c38:	70e2                	ld	ra,56(sp)
    80003c3a:	7442                	ld	s0,48(sp)
    80003c3c:	74a2                	ld	s1,40(sp)
    80003c3e:	7902                	ld	s2,32(sp)
    80003c40:	69e2                	ld	s3,24(sp)
    80003c42:	6a42                	ld	s4,16(sp)
    80003c44:	6121                	addi	sp,sp,64
    80003c46:	8082                	ret

0000000080003c48 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c48:	711d                	addi	sp,sp,-96
    80003c4a:	ec86                	sd	ra,88(sp)
    80003c4c:	e8a2                	sd	s0,80(sp)
    80003c4e:	e4a6                	sd	s1,72(sp)
    80003c50:	e0ca                	sd	s2,64(sp)
    80003c52:	fc4e                	sd	s3,56(sp)
    80003c54:	f852                	sd	s4,48(sp)
    80003c56:	f456                	sd	s5,40(sp)
    80003c58:	f05a                	sd	s6,32(sp)
    80003c5a:	ec5e                	sd	s7,24(sp)
    80003c5c:	e862                	sd	s8,16(sp)
    80003c5e:	e466                	sd	s9,8(sp)
    80003c60:	e06a                	sd	s10,0(sp)
    80003c62:	1080                	addi	s0,sp,96
    80003c64:	84aa                	mv	s1,a0
    80003c66:	8b2e                	mv	s6,a1
    80003c68:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c6a:	00054703          	lbu	a4,0(a0)
    80003c6e:	02f00793          	li	a5,47
    80003c72:	02f70363          	beq	a4,a5,80003c98 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c76:	ffffe097          	auipc	ra,0xffffe
    80003c7a:	d36080e7          	jalr	-714(ra) # 800019ac <myproc>
    80003c7e:	15053503          	ld	a0,336(a0)
    80003c82:	00000097          	auipc	ra,0x0
    80003c86:	9f4080e7          	jalr	-1548(ra) # 80003676 <idup>
    80003c8a:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003c8c:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003c90:	4cb5                	li	s9,13
  len = path - s;
    80003c92:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c94:	4c05                	li	s8,1
    80003c96:	a87d                	j	80003d54 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003c98:	4585                	li	a1,1
    80003c9a:	4505                	li	a0,1
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	6de080e7          	jalr	1758(ra) # 8000337a <iget>
    80003ca4:	8a2a                	mv	s4,a0
    80003ca6:	b7dd                	j	80003c8c <namex+0x44>
      iunlockput(ip);
    80003ca8:	8552                	mv	a0,s4
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	c6c080e7          	jalr	-916(ra) # 80003916 <iunlockput>
      return 0;
    80003cb2:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cb4:	8552                	mv	a0,s4
    80003cb6:	60e6                	ld	ra,88(sp)
    80003cb8:	6446                	ld	s0,80(sp)
    80003cba:	64a6                	ld	s1,72(sp)
    80003cbc:	6906                	ld	s2,64(sp)
    80003cbe:	79e2                	ld	s3,56(sp)
    80003cc0:	7a42                	ld	s4,48(sp)
    80003cc2:	7aa2                	ld	s5,40(sp)
    80003cc4:	7b02                	ld	s6,32(sp)
    80003cc6:	6be2                	ld	s7,24(sp)
    80003cc8:	6c42                	ld	s8,16(sp)
    80003cca:	6ca2                	ld	s9,8(sp)
    80003ccc:	6d02                	ld	s10,0(sp)
    80003cce:	6125                	addi	sp,sp,96
    80003cd0:	8082                	ret
      iunlock(ip);
    80003cd2:	8552                	mv	a0,s4
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	aa2080e7          	jalr	-1374(ra) # 80003776 <iunlock>
      return ip;
    80003cdc:	bfe1                	j	80003cb4 <namex+0x6c>
      iunlockput(ip);
    80003cde:	8552                	mv	a0,s4
    80003ce0:	00000097          	auipc	ra,0x0
    80003ce4:	c36080e7          	jalr	-970(ra) # 80003916 <iunlockput>
      return 0;
    80003ce8:	8a4e                	mv	s4,s3
    80003cea:	b7e9                	j	80003cb4 <namex+0x6c>
  len = path - s;
    80003cec:	40998633          	sub	a2,s3,s1
    80003cf0:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003cf4:	09acd863          	bge	s9,s10,80003d84 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003cf8:	4639                	li	a2,14
    80003cfa:	85a6                	mv	a1,s1
    80003cfc:	8556                	mv	a0,s5
    80003cfe:	ffffd097          	auipc	ra,0xffffd
    80003d02:	030080e7          	jalr	48(ra) # 80000d2e <memmove>
    80003d06:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d08:	0004c783          	lbu	a5,0(s1)
    80003d0c:	01279763          	bne	a5,s2,80003d1a <namex+0xd2>
    path++;
    80003d10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d12:	0004c783          	lbu	a5,0(s1)
    80003d16:	ff278de3          	beq	a5,s2,80003d10 <namex+0xc8>
    ilock(ip);
    80003d1a:	8552                	mv	a0,s4
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	998080e7          	jalr	-1640(ra) # 800036b4 <ilock>
    if(ip->type != T_DIR){
    80003d24:	044a1783          	lh	a5,68(s4)
    80003d28:	f98790e3          	bne	a5,s8,80003ca8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003d2c:	000b0563          	beqz	s6,80003d36 <namex+0xee>
    80003d30:	0004c783          	lbu	a5,0(s1)
    80003d34:	dfd9                	beqz	a5,80003cd2 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d36:	865e                	mv	a2,s7
    80003d38:	85d6                	mv	a1,s5
    80003d3a:	8552                	mv	a0,s4
    80003d3c:	00000097          	auipc	ra,0x0
    80003d40:	e5c080e7          	jalr	-420(ra) # 80003b98 <dirlookup>
    80003d44:	89aa                	mv	s3,a0
    80003d46:	dd41                	beqz	a0,80003cde <namex+0x96>
    iunlockput(ip);
    80003d48:	8552                	mv	a0,s4
    80003d4a:	00000097          	auipc	ra,0x0
    80003d4e:	bcc080e7          	jalr	-1076(ra) # 80003916 <iunlockput>
    ip = next;
    80003d52:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003d54:	0004c783          	lbu	a5,0(s1)
    80003d58:	01279763          	bne	a5,s2,80003d66 <namex+0x11e>
    path++;
    80003d5c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d5e:	0004c783          	lbu	a5,0(s1)
    80003d62:	ff278de3          	beq	a5,s2,80003d5c <namex+0x114>
  if(*path == 0)
    80003d66:	cb9d                	beqz	a5,80003d9c <namex+0x154>
  while(*path != '/' && *path != 0)
    80003d68:	0004c783          	lbu	a5,0(s1)
    80003d6c:	89a6                	mv	s3,s1
  len = path - s;
    80003d6e:	8d5e                	mv	s10,s7
    80003d70:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003d72:	01278963          	beq	a5,s2,80003d84 <namex+0x13c>
    80003d76:	dbbd                	beqz	a5,80003cec <namex+0xa4>
    path++;
    80003d78:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003d7a:	0009c783          	lbu	a5,0(s3)
    80003d7e:	ff279ce3          	bne	a5,s2,80003d76 <namex+0x12e>
    80003d82:	b7ad                	j	80003cec <namex+0xa4>
    memmove(name, s, len);
    80003d84:	2601                	sext.w	a2,a2
    80003d86:	85a6                	mv	a1,s1
    80003d88:	8556                	mv	a0,s5
    80003d8a:	ffffd097          	auipc	ra,0xffffd
    80003d8e:	fa4080e7          	jalr	-92(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003d92:	9d56                	add	s10,s10,s5
    80003d94:	000d0023          	sb	zero,0(s10)
    80003d98:	84ce                	mv	s1,s3
    80003d9a:	b7bd                	j	80003d08 <namex+0xc0>
  if(nameiparent){
    80003d9c:	f00b0ce3          	beqz	s6,80003cb4 <namex+0x6c>
    iput(ip);
    80003da0:	8552                	mv	a0,s4
    80003da2:	00000097          	auipc	ra,0x0
    80003da6:	acc080e7          	jalr	-1332(ra) # 8000386e <iput>
    return 0;
    80003daa:	4a01                	li	s4,0
    80003dac:	b721                	j	80003cb4 <namex+0x6c>

0000000080003dae <dirlink>:
{
    80003dae:	7139                	addi	sp,sp,-64
    80003db0:	fc06                	sd	ra,56(sp)
    80003db2:	f822                	sd	s0,48(sp)
    80003db4:	f426                	sd	s1,40(sp)
    80003db6:	f04a                	sd	s2,32(sp)
    80003db8:	ec4e                	sd	s3,24(sp)
    80003dba:	e852                	sd	s4,16(sp)
    80003dbc:	0080                	addi	s0,sp,64
    80003dbe:	892a                	mv	s2,a0
    80003dc0:	8a2e                	mv	s4,a1
    80003dc2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dc4:	4601                	li	a2,0
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	dd2080e7          	jalr	-558(ra) # 80003b98 <dirlookup>
    80003dce:	e93d                	bnez	a0,80003e44 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd0:	04c92483          	lw	s1,76(s2)
    80003dd4:	c49d                	beqz	s1,80003e02 <dirlink+0x54>
    80003dd6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dd8:	4741                	li	a4,16
    80003dda:	86a6                	mv	a3,s1
    80003ddc:	fc040613          	addi	a2,s0,-64
    80003de0:	4581                	li	a1,0
    80003de2:	854a                	mv	a0,s2
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	b84080e7          	jalr	-1148(ra) # 80003968 <readi>
    80003dec:	47c1                	li	a5,16
    80003dee:	06f51163          	bne	a0,a5,80003e50 <dirlink+0xa2>
    if(de.inum == 0)
    80003df2:	fc045783          	lhu	a5,-64(s0)
    80003df6:	c791                	beqz	a5,80003e02 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df8:	24c1                	addiw	s1,s1,16
    80003dfa:	04c92783          	lw	a5,76(s2)
    80003dfe:	fcf4ede3          	bltu	s1,a5,80003dd8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e02:	4639                	li	a2,14
    80003e04:	85d2                	mv	a1,s4
    80003e06:	fc240513          	addi	a0,s0,-62
    80003e0a:	ffffd097          	auipc	ra,0xffffd
    80003e0e:	fd4080e7          	jalr	-44(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003e12:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e16:	4741                	li	a4,16
    80003e18:	86a6                	mv	a3,s1
    80003e1a:	fc040613          	addi	a2,s0,-64
    80003e1e:	4581                	li	a1,0
    80003e20:	854a                	mv	a0,s2
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	c3e080e7          	jalr	-962(ra) # 80003a60 <writei>
    80003e2a:	1541                	addi	a0,a0,-16
    80003e2c:	00a03533          	snez	a0,a0
    80003e30:	40a00533          	neg	a0,a0
}
    80003e34:	70e2                	ld	ra,56(sp)
    80003e36:	7442                	ld	s0,48(sp)
    80003e38:	74a2                	ld	s1,40(sp)
    80003e3a:	7902                	ld	s2,32(sp)
    80003e3c:	69e2                	ld	s3,24(sp)
    80003e3e:	6a42                	ld	s4,16(sp)
    80003e40:	6121                	addi	sp,sp,64
    80003e42:	8082                	ret
    iput(ip);
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	a2a080e7          	jalr	-1494(ra) # 8000386e <iput>
    return -1;
    80003e4c:	557d                	li	a0,-1
    80003e4e:	b7dd                	j	80003e34 <dirlink+0x86>
      panic("dirlink read");
    80003e50:	00004517          	auipc	a0,0x4
    80003e54:	7e850513          	addi	a0,a0,2024 # 80008638 <syscalls+0x1d0>
    80003e58:	ffffc097          	auipc	ra,0xffffc
    80003e5c:	6e8080e7          	jalr	1768(ra) # 80000540 <panic>

0000000080003e60 <namei>:

struct inode*
namei(char *path)
{
    80003e60:	1101                	addi	sp,sp,-32
    80003e62:	ec06                	sd	ra,24(sp)
    80003e64:	e822                	sd	s0,16(sp)
    80003e66:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e68:	fe040613          	addi	a2,s0,-32
    80003e6c:	4581                	li	a1,0
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	dda080e7          	jalr	-550(ra) # 80003c48 <namex>
}
    80003e76:	60e2                	ld	ra,24(sp)
    80003e78:	6442                	ld	s0,16(sp)
    80003e7a:	6105                	addi	sp,sp,32
    80003e7c:	8082                	ret

0000000080003e7e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e7e:	1141                	addi	sp,sp,-16
    80003e80:	e406                	sd	ra,8(sp)
    80003e82:	e022                	sd	s0,0(sp)
    80003e84:	0800                	addi	s0,sp,16
    80003e86:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e88:	4585                	li	a1,1
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	dbe080e7          	jalr	-578(ra) # 80003c48 <namex>
}
    80003e92:	60a2                	ld	ra,8(sp)
    80003e94:	6402                	ld	s0,0(sp)
    80003e96:	0141                	addi	sp,sp,16
    80003e98:	8082                	ret

0000000080003e9a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003e9a:	1101                	addi	sp,sp,-32
    80003e9c:	ec06                	sd	ra,24(sp)
    80003e9e:	e822                	sd	s0,16(sp)
    80003ea0:	e426                	sd	s1,8(sp)
    80003ea2:	e04a                	sd	s2,0(sp)
    80003ea4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ea6:	0001d917          	auipc	s2,0x1d
    80003eaa:	c9a90913          	addi	s2,s2,-870 # 80020b40 <log>
    80003eae:	01892583          	lw	a1,24(s2)
    80003eb2:	02892503          	lw	a0,40(s2)
    80003eb6:	fffff097          	auipc	ra,0xfffff
    80003eba:	fe6080e7          	jalr	-26(ra) # 80002e9c <bread>
    80003ebe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ec0:	02c92683          	lw	a3,44(s2)
    80003ec4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ec6:	02d05863          	blez	a3,80003ef6 <write_head+0x5c>
    80003eca:	0001d797          	auipc	a5,0x1d
    80003ece:	ca678793          	addi	a5,a5,-858 # 80020b70 <log+0x30>
    80003ed2:	05c50713          	addi	a4,a0,92
    80003ed6:	36fd                	addiw	a3,a3,-1
    80003ed8:	02069613          	slli	a2,a3,0x20
    80003edc:	01e65693          	srli	a3,a2,0x1e
    80003ee0:	0001d617          	auipc	a2,0x1d
    80003ee4:	c9460613          	addi	a2,a2,-876 # 80020b74 <log+0x34>
    80003ee8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003eea:	4390                	lw	a2,0(a5)
    80003eec:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003eee:	0791                	addi	a5,a5,4
    80003ef0:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003ef2:	fed79ce3          	bne	a5,a3,80003eea <write_head+0x50>
  }
  bwrite(buf);
    80003ef6:	8526                	mv	a0,s1
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	096080e7          	jalr	150(ra) # 80002f8e <bwrite>
  brelse(buf);
    80003f00:	8526                	mv	a0,s1
    80003f02:	fffff097          	auipc	ra,0xfffff
    80003f06:	0ca080e7          	jalr	202(ra) # 80002fcc <brelse>
}
    80003f0a:	60e2                	ld	ra,24(sp)
    80003f0c:	6442                	ld	s0,16(sp)
    80003f0e:	64a2                	ld	s1,8(sp)
    80003f10:	6902                	ld	s2,0(sp)
    80003f12:	6105                	addi	sp,sp,32
    80003f14:	8082                	ret

0000000080003f16 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f16:	0001d797          	auipc	a5,0x1d
    80003f1a:	c567a783          	lw	a5,-938(a5) # 80020b6c <log+0x2c>
    80003f1e:	0af05d63          	blez	a5,80003fd8 <install_trans+0xc2>
{
    80003f22:	7139                	addi	sp,sp,-64
    80003f24:	fc06                	sd	ra,56(sp)
    80003f26:	f822                	sd	s0,48(sp)
    80003f28:	f426                	sd	s1,40(sp)
    80003f2a:	f04a                	sd	s2,32(sp)
    80003f2c:	ec4e                	sd	s3,24(sp)
    80003f2e:	e852                	sd	s4,16(sp)
    80003f30:	e456                	sd	s5,8(sp)
    80003f32:	e05a                	sd	s6,0(sp)
    80003f34:	0080                	addi	s0,sp,64
    80003f36:	8b2a                	mv	s6,a0
    80003f38:	0001da97          	auipc	s5,0x1d
    80003f3c:	c38a8a93          	addi	s5,s5,-968 # 80020b70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f40:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f42:	0001d997          	auipc	s3,0x1d
    80003f46:	bfe98993          	addi	s3,s3,-1026 # 80020b40 <log>
    80003f4a:	a00d                	j	80003f6c <install_trans+0x56>
    brelse(lbuf);
    80003f4c:	854a                	mv	a0,s2
    80003f4e:	fffff097          	auipc	ra,0xfffff
    80003f52:	07e080e7          	jalr	126(ra) # 80002fcc <brelse>
    brelse(dbuf);
    80003f56:	8526                	mv	a0,s1
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	074080e7          	jalr	116(ra) # 80002fcc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f60:	2a05                	addiw	s4,s4,1
    80003f62:	0a91                	addi	s5,s5,4
    80003f64:	02c9a783          	lw	a5,44(s3)
    80003f68:	04fa5e63          	bge	s4,a5,80003fc4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f6c:	0189a583          	lw	a1,24(s3)
    80003f70:	014585bb          	addw	a1,a1,s4
    80003f74:	2585                	addiw	a1,a1,1
    80003f76:	0289a503          	lw	a0,40(s3)
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	f22080e7          	jalr	-222(ra) # 80002e9c <bread>
    80003f82:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f84:	000aa583          	lw	a1,0(s5)
    80003f88:	0289a503          	lw	a0,40(s3)
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	f10080e7          	jalr	-240(ra) # 80002e9c <bread>
    80003f94:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f96:	40000613          	li	a2,1024
    80003f9a:	05890593          	addi	a1,s2,88
    80003f9e:	05850513          	addi	a0,a0,88
    80003fa2:	ffffd097          	auipc	ra,0xffffd
    80003fa6:	d8c080e7          	jalr	-628(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80003faa:	8526                	mv	a0,s1
    80003fac:	fffff097          	auipc	ra,0xfffff
    80003fb0:	fe2080e7          	jalr	-30(ra) # 80002f8e <bwrite>
    if(recovering == 0)
    80003fb4:	f80b1ce3          	bnez	s6,80003f4c <install_trans+0x36>
      bunpin(dbuf);
    80003fb8:	8526                	mv	a0,s1
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	0ec080e7          	jalr	236(ra) # 800030a6 <bunpin>
    80003fc2:	b769                	j	80003f4c <install_trans+0x36>
}
    80003fc4:	70e2                	ld	ra,56(sp)
    80003fc6:	7442                	ld	s0,48(sp)
    80003fc8:	74a2                	ld	s1,40(sp)
    80003fca:	7902                	ld	s2,32(sp)
    80003fcc:	69e2                	ld	s3,24(sp)
    80003fce:	6a42                	ld	s4,16(sp)
    80003fd0:	6aa2                	ld	s5,8(sp)
    80003fd2:	6b02                	ld	s6,0(sp)
    80003fd4:	6121                	addi	sp,sp,64
    80003fd6:	8082                	ret
    80003fd8:	8082                	ret

0000000080003fda <initlog>:
{
    80003fda:	7179                	addi	sp,sp,-48
    80003fdc:	f406                	sd	ra,40(sp)
    80003fde:	f022                	sd	s0,32(sp)
    80003fe0:	ec26                	sd	s1,24(sp)
    80003fe2:	e84a                	sd	s2,16(sp)
    80003fe4:	e44e                	sd	s3,8(sp)
    80003fe6:	1800                	addi	s0,sp,48
    80003fe8:	892a                	mv	s2,a0
    80003fea:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003fec:	0001d497          	auipc	s1,0x1d
    80003ff0:	b5448493          	addi	s1,s1,-1196 # 80020b40 <log>
    80003ff4:	00004597          	auipc	a1,0x4
    80003ff8:	65458593          	addi	a1,a1,1620 # 80008648 <syscalls+0x1e0>
    80003ffc:	8526                	mv	a0,s1
    80003ffe:	ffffd097          	auipc	ra,0xffffd
    80004002:	b48080e7          	jalr	-1208(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004006:	0149a583          	lw	a1,20(s3)
    8000400a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000400c:	0109a783          	lw	a5,16(s3)
    80004010:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004012:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004016:	854a                	mv	a0,s2
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	e84080e7          	jalr	-380(ra) # 80002e9c <bread>
  log.lh.n = lh->n;
    80004020:	4d34                	lw	a3,88(a0)
    80004022:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004024:	02d05663          	blez	a3,80004050 <initlog+0x76>
    80004028:	05c50793          	addi	a5,a0,92
    8000402c:	0001d717          	auipc	a4,0x1d
    80004030:	b4470713          	addi	a4,a4,-1212 # 80020b70 <log+0x30>
    80004034:	36fd                	addiw	a3,a3,-1
    80004036:	02069613          	slli	a2,a3,0x20
    8000403a:	01e65693          	srli	a3,a2,0x1e
    8000403e:	06050613          	addi	a2,a0,96
    80004042:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004044:	4390                	lw	a2,0(a5)
    80004046:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004048:	0791                	addi	a5,a5,4
    8000404a:	0711                	addi	a4,a4,4
    8000404c:	fed79ce3          	bne	a5,a3,80004044 <initlog+0x6a>
  brelse(buf);
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	f7c080e7          	jalr	-132(ra) # 80002fcc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004058:	4505                	li	a0,1
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	ebc080e7          	jalr	-324(ra) # 80003f16 <install_trans>
  log.lh.n = 0;
    80004062:	0001d797          	auipc	a5,0x1d
    80004066:	b007a523          	sw	zero,-1270(a5) # 80020b6c <log+0x2c>
  write_head(); // clear the log
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	e30080e7          	jalr	-464(ra) # 80003e9a <write_head>
}
    80004072:	70a2                	ld	ra,40(sp)
    80004074:	7402                	ld	s0,32(sp)
    80004076:	64e2                	ld	s1,24(sp)
    80004078:	6942                	ld	s2,16(sp)
    8000407a:	69a2                	ld	s3,8(sp)
    8000407c:	6145                	addi	sp,sp,48
    8000407e:	8082                	ret

0000000080004080 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004080:	1101                	addi	sp,sp,-32
    80004082:	ec06                	sd	ra,24(sp)
    80004084:	e822                	sd	s0,16(sp)
    80004086:	e426                	sd	s1,8(sp)
    80004088:	e04a                	sd	s2,0(sp)
    8000408a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000408c:	0001d517          	auipc	a0,0x1d
    80004090:	ab450513          	addi	a0,a0,-1356 # 80020b40 <log>
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	b42080e7          	jalr	-1214(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000409c:	0001d497          	auipc	s1,0x1d
    800040a0:	aa448493          	addi	s1,s1,-1372 # 80020b40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040a4:	4979                	li	s2,30
    800040a6:	a039                	j	800040b4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040a8:	85a6                	mv	a1,s1
    800040aa:	8526                	mv	a0,s1
    800040ac:	ffffe097          	auipc	ra,0xffffe
    800040b0:	fa8080e7          	jalr	-88(ra) # 80002054 <sleep>
    if(log.committing){
    800040b4:	50dc                	lw	a5,36(s1)
    800040b6:	fbed                	bnez	a5,800040a8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040b8:	5098                	lw	a4,32(s1)
    800040ba:	2705                	addiw	a4,a4,1
    800040bc:	0007069b          	sext.w	a3,a4
    800040c0:	0027179b          	slliw	a5,a4,0x2
    800040c4:	9fb9                	addw	a5,a5,a4
    800040c6:	0017979b          	slliw	a5,a5,0x1
    800040ca:	54d8                	lw	a4,44(s1)
    800040cc:	9fb9                	addw	a5,a5,a4
    800040ce:	00f95963          	bge	s2,a5,800040e0 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040d2:	85a6                	mv	a1,s1
    800040d4:	8526                	mv	a0,s1
    800040d6:	ffffe097          	auipc	ra,0xffffe
    800040da:	f7e080e7          	jalr	-130(ra) # 80002054 <sleep>
    800040de:	bfd9                	j	800040b4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040e0:	0001d517          	auipc	a0,0x1d
    800040e4:	a6050513          	addi	a0,a0,-1440 # 80020b40 <log>
    800040e8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040ea:	ffffd097          	auipc	ra,0xffffd
    800040ee:	ba0080e7          	jalr	-1120(ra) # 80000c8a <release>
      break;
    }
  }
}
    800040f2:	60e2                	ld	ra,24(sp)
    800040f4:	6442                	ld	s0,16(sp)
    800040f6:	64a2                	ld	s1,8(sp)
    800040f8:	6902                	ld	s2,0(sp)
    800040fa:	6105                	addi	sp,sp,32
    800040fc:	8082                	ret

00000000800040fe <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800040fe:	7139                	addi	sp,sp,-64
    80004100:	fc06                	sd	ra,56(sp)
    80004102:	f822                	sd	s0,48(sp)
    80004104:	f426                	sd	s1,40(sp)
    80004106:	f04a                	sd	s2,32(sp)
    80004108:	ec4e                	sd	s3,24(sp)
    8000410a:	e852                	sd	s4,16(sp)
    8000410c:	e456                	sd	s5,8(sp)
    8000410e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004110:	0001d497          	auipc	s1,0x1d
    80004114:	a3048493          	addi	s1,s1,-1488 # 80020b40 <log>
    80004118:	8526                	mv	a0,s1
    8000411a:	ffffd097          	auipc	ra,0xffffd
    8000411e:	abc080e7          	jalr	-1348(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004122:	509c                	lw	a5,32(s1)
    80004124:	37fd                	addiw	a5,a5,-1
    80004126:	0007891b          	sext.w	s2,a5
    8000412a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000412c:	50dc                	lw	a5,36(s1)
    8000412e:	e7b9                	bnez	a5,8000417c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004130:	04091e63          	bnez	s2,8000418c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004134:	0001d497          	auipc	s1,0x1d
    80004138:	a0c48493          	addi	s1,s1,-1524 # 80020b40 <log>
    8000413c:	4785                	li	a5,1
    8000413e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004140:	8526                	mv	a0,s1
    80004142:	ffffd097          	auipc	ra,0xffffd
    80004146:	b48080e7          	jalr	-1208(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000414a:	54dc                	lw	a5,44(s1)
    8000414c:	06f04763          	bgtz	a5,800041ba <end_op+0xbc>
    acquire(&log.lock);
    80004150:	0001d497          	auipc	s1,0x1d
    80004154:	9f048493          	addi	s1,s1,-1552 # 80020b40 <log>
    80004158:	8526                	mv	a0,s1
    8000415a:	ffffd097          	auipc	ra,0xffffd
    8000415e:	a7c080e7          	jalr	-1412(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004162:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004166:	8526                	mv	a0,s1
    80004168:	ffffe097          	auipc	ra,0xffffe
    8000416c:	f50080e7          	jalr	-176(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004170:	8526                	mv	a0,s1
    80004172:	ffffd097          	auipc	ra,0xffffd
    80004176:	b18080e7          	jalr	-1256(ra) # 80000c8a <release>
}
    8000417a:	a03d                	j	800041a8 <end_op+0xaa>
    panic("log.committing");
    8000417c:	00004517          	auipc	a0,0x4
    80004180:	4d450513          	addi	a0,a0,1236 # 80008650 <syscalls+0x1e8>
    80004184:	ffffc097          	auipc	ra,0xffffc
    80004188:	3bc080e7          	jalr	956(ra) # 80000540 <panic>
    wakeup(&log);
    8000418c:	0001d497          	auipc	s1,0x1d
    80004190:	9b448493          	addi	s1,s1,-1612 # 80020b40 <log>
    80004194:	8526                	mv	a0,s1
    80004196:	ffffe097          	auipc	ra,0xffffe
    8000419a:	f22080e7          	jalr	-222(ra) # 800020b8 <wakeup>
  release(&log.lock);
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffd097          	auipc	ra,0xffffd
    800041a4:	aea080e7          	jalr	-1302(ra) # 80000c8a <release>
}
    800041a8:	70e2                	ld	ra,56(sp)
    800041aa:	7442                	ld	s0,48(sp)
    800041ac:	74a2                	ld	s1,40(sp)
    800041ae:	7902                	ld	s2,32(sp)
    800041b0:	69e2                	ld	s3,24(sp)
    800041b2:	6a42                	ld	s4,16(sp)
    800041b4:	6aa2                	ld	s5,8(sp)
    800041b6:	6121                	addi	sp,sp,64
    800041b8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ba:	0001da97          	auipc	s5,0x1d
    800041be:	9b6a8a93          	addi	s5,s5,-1610 # 80020b70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041c2:	0001da17          	auipc	s4,0x1d
    800041c6:	97ea0a13          	addi	s4,s4,-1666 # 80020b40 <log>
    800041ca:	018a2583          	lw	a1,24(s4)
    800041ce:	012585bb          	addw	a1,a1,s2
    800041d2:	2585                	addiw	a1,a1,1
    800041d4:	028a2503          	lw	a0,40(s4)
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	cc4080e7          	jalr	-828(ra) # 80002e9c <bread>
    800041e0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041e2:	000aa583          	lw	a1,0(s5)
    800041e6:	028a2503          	lw	a0,40(s4)
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	cb2080e7          	jalr	-846(ra) # 80002e9c <bread>
    800041f2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041f4:	40000613          	li	a2,1024
    800041f8:	05850593          	addi	a1,a0,88
    800041fc:	05848513          	addi	a0,s1,88
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	b2e080e7          	jalr	-1234(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004208:	8526                	mv	a0,s1
    8000420a:	fffff097          	auipc	ra,0xfffff
    8000420e:	d84080e7          	jalr	-636(ra) # 80002f8e <bwrite>
    brelse(from);
    80004212:	854e                	mv	a0,s3
    80004214:	fffff097          	auipc	ra,0xfffff
    80004218:	db8080e7          	jalr	-584(ra) # 80002fcc <brelse>
    brelse(to);
    8000421c:	8526                	mv	a0,s1
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	dae080e7          	jalr	-594(ra) # 80002fcc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004226:	2905                	addiw	s2,s2,1
    80004228:	0a91                	addi	s5,s5,4
    8000422a:	02ca2783          	lw	a5,44(s4)
    8000422e:	f8f94ee3          	blt	s2,a5,800041ca <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004232:	00000097          	auipc	ra,0x0
    80004236:	c68080e7          	jalr	-920(ra) # 80003e9a <write_head>
    install_trans(0); // Now install writes to home locations
    8000423a:	4501                	li	a0,0
    8000423c:	00000097          	auipc	ra,0x0
    80004240:	cda080e7          	jalr	-806(ra) # 80003f16 <install_trans>
    log.lh.n = 0;
    80004244:	0001d797          	auipc	a5,0x1d
    80004248:	9207a423          	sw	zero,-1752(a5) # 80020b6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	c4e080e7          	jalr	-946(ra) # 80003e9a <write_head>
    80004254:	bdf5                	j	80004150 <end_op+0x52>

0000000080004256 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004256:	1101                	addi	sp,sp,-32
    80004258:	ec06                	sd	ra,24(sp)
    8000425a:	e822                	sd	s0,16(sp)
    8000425c:	e426                	sd	s1,8(sp)
    8000425e:	e04a                	sd	s2,0(sp)
    80004260:	1000                	addi	s0,sp,32
    80004262:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004264:	0001d917          	auipc	s2,0x1d
    80004268:	8dc90913          	addi	s2,s2,-1828 # 80020b40 <log>
    8000426c:	854a                	mv	a0,s2
    8000426e:	ffffd097          	auipc	ra,0xffffd
    80004272:	968080e7          	jalr	-1688(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004276:	02c92603          	lw	a2,44(s2)
    8000427a:	47f5                	li	a5,29
    8000427c:	06c7c563          	blt	a5,a2,800042e6 <log_write+0x90>
    80004280:	0001d797          	auipc	a5,0x1d
    80004284:	8dc7a783          	lw	a5,-1828(a5) # 80020b5c <log+0x1c>
    80004288:	37fd                	addiw	a5,a5,-1
    8000428a:	04f65e63          	bge	a2,a5,800042e6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000428e:	0001d797          	auipc	a5,0x1d
    80004292:	8d27a783          	lw	a5,-1838(a5) # 80020b60 <log+0x20>
    80004296:	06f05063          	blez	a5,800042f6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000429a:	4781                	li	a5,0
    8000429c:	06c05563          	blez	a2,80004306 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042a0:	44cc                	lw	a1,12(s1)
    800042a2:	0001d717          	auipc	a4,0x1d
    800042a6:	8ce70713          	addi	a4,a4,-1842 # 80020b70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042aa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042ac:	4314                	lw	a3,0(a4)
    800042ae:	04b68c63          	beq	a3,a1,80004306 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800042b2:	2785                	addiw	a5,a5,1
    800042b4:	0711                	addi	a4,a4,4
    800042b6:	fef61be3          	bne	a2,a5,800042ac <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042ba:	0621                	addi	a2,a2,8
    800042bc:	060a                	slli	a2,a2,0x2
    800042be:	0001d797          	auipc	a5,0x1d
    800042c2:	88278793          	addi	a5,a5,-1918 # 80020b40 <log>
    800042c6:	97b2                	add	a5,a5,a2
    800042c8:	44d8                	lw	a4,12(s1)
    800042ca:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042cc:	8526                	mv	a0,s1
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	d9c080e7          	jalr	-612(ra) # 8000306a <bpin>
    log.lh.n++;
    800042d6:	0001d717          	auipc	a4,0x1d
    800042da:	86a70713          	addi	a4,a4,-1942 # 80020b40 <log>
    800042de:	575c                	lw	a5,44(a4)
    800042e0:	2785                	addiw	a5,a5,1
    800042e2:	d75c                	sw	a5,44(a4)
    800042e4:	a82d                	j	8000431e <log_write+0xc8>
    panic("too big a transaction");
    800042e6:	00004517          	auipc	a0,0x4
    800042ea:	37a50513          	addi	a0,a0,890 # 80008660 <syscalls+0x1f8>
    800042ee:	ffffc097          	auipc	ra,0xffffc
    800042f2:	252080e7          	jalr	594(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800042f6:	00004517          	auipc	a0,0x4
    800042fa:	38250513          	addi	a0,a0,898 # 80008678 <syscalls+0x210>
    800042fe:	ffffc097          	auipc	ra,0xffffc
    80004302:	242080e7          	jalr	578(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004306:	00878693          	addi	a3,a5,8
    8000430a:	068a                	slli	a3,a3,0x2
    8000430c:	0001d717          	auipc	a4,0x1d
    80004310:	83470713          	addi	a4,a4,-1996 # 80020b40 <log>
    80004314:	9736                	add	a4,a4,a3
    80004316:	44d4                	lw	a3,12(s1)
    80004318:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000431a:	faf609e3          	beq	a2,a5,800042cc <log_write+0x76>
  }
  release(&log.lock);
    8000431e:	0001d517          	auipc	a0,0x1d
    80004322:	82250513          	addi	a0,a0,-2014 # 80020b40 <log>
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	964080e7          	jalr	-1692(ra) # 80000c8a <release>
}
    8000432e:	60e2                	ld	ra,24(sp)
    80004330:	6442                	ld	s0,16(sp)
    80004332:	64a2                	ld	s1,8(sp)
    80004334:	6902                	ld	s2,0(sp)
    80004336:	6105                	addi	sp,sp,32
    80004338:	8082                	ret

000000008000433a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000433a:	1101                	addi	sp,sp,-32
    8000433c:	ec06                	sd	ra,24(sp)
    8000433e:	e822                	sd	s0,16(sp)
    80004340:	e426                	sd	s1,8(sp)
    80004342:	e04a                	sd	s2,0(sp)
    80004344:	1000                	addi	s0,sp,32
    80004346:	84aa                	mv	s1,a0
    80004348:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000434a:	00004597          	auipc	a1,0x4
    8000434e:	34e58593          	addi	a1,a1,846 # 80008698 <syscalls+0x230>
    80004352:	0521                	addi	a0,a0,8
    80004354:	ffffc097          	auipc	ra,0xffffc
    80004358:	7f2080e7          	jalr	2034(ra) # 80000b46 <initlock>
  lk->name = name;
    8000435c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004360:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004364:	0204a423          	sw	zero,40(s1)
}
    80004368:	60e2                	ld	ra,24(sp)
    8000436a:	6442                	ld	s0,16(sp)
    8000436c:	64a2                	ld	s1,8(sp)
    8000436e:	6902                	ld	s2,0(sp)
    80004370:	6105                	addi	sp,sp,32
    80004372:	8082                	ret

0000000080004374 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004374:	1101                	addi	sp,sp,-32
    80004376:	ec06                	sd	ra,24(sp)
    80004378:	e822                	sd	s0,16(sp)
    8000437a:	e426                	sd	s1,8(sp)
    8000437c:	e04a                	sd	s2,0(sp)
    8000437e:	1000                	addi	s0,sp,32
    80004380:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004382:	00850913          	addi	s2,a0,8
    80004386:	854a                	mv	a0,s2
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	84e080e7          	jalr	-1970(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004390:	409c                	lw	a5,0(s1)
    80004392:	cb89                	beqz	a5,800043a4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004394:	85ca                	mv	a1,s2
    80004396:	8526                	mv	a0,s1
    80004398:	ffffe097          	auipc	ra,0xffffe
    8000439c:	cbc080e7          	jalr	-836(ra) # 80002054 <sleep>
  while (lk->locked) {
    800043a0:	409c                	lw	a5,0(s1)
    800043a2:	fbed                	bnez	a5,80004394 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043a4:	4785                	li	a5,1
    800043a6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	604080e7          	jalr	1540(ra) # 800019ac <myproc>
    800043b0:	591c                	lw	a5,48(a0)
    800043b2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043b4:	854a                	mv	a0,s2
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	8d4080e7          	jalr	-1836(ra) # 80000c8a <release>
}
    800043be:	60e2                	ld	ra,24(sp)
    800043c0:	6442                	ld	s0,16(sp)
    800043c2:	64a2                	ld	s1,8(sp)
    800043c4:	6902                	ld	s2,0(sp)
    800043c6:	6105                	addi	sp,sp,32
    800043c8:	8082                	ret

00000000800043ca <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043ca:	1101                	addi	sp,sp,-32
    800043cc:	ec06                	sd	ra,24(sp)
    800043ce:	e822                	sd	s0,16(sp)
    800043d0:	e426                	sd	s1,8(sp)
    800043d2:	e04a                	sd	s2,0(sp)
    800043d4:	1000                	addi	s0,sp,32
    800043d6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d8:	00850913          	addi	s2,a0,8
    800043dc:	854a                	mv	a0,s2
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	7f8080e7          	jalr	2040(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800043e6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043ea:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043ee:	8526                	mv	a0,s1
    800043f0:	ffffe097          	auipc	ra,0xffffe
    800043f4:	cc8080e7          	jalr	-824(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    800043f8:	854a                	mv	a0,s2
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	890080e7          	jalr	-1904(ra) # 80000c8a <release>
}
    80004402:	60e2                	ld	ra,24(sp)
    80004404:	6442                	ld	s0,16(sp)
    80004406:	64a2                	ld	s1,8(sp)
    80004408:	6902                	ld	s2,0(sp)
    8000440a:	6105                	addi	sp,sp,32
    8000440c:	8082                	ret

000000008000440e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000440e:	7179                	addi	sp,sp,-48
    80004410:	f406                	sd	ra,40(sp)
    80004412:	f022                	sd	s0,32(sp)
    80004414:	ec26                	sd	s1,24(sp)
    80004416:	e84a                	sd	s2,16(sp)
    80004418:	e44e                	sd	s3,8(sp)
    8000441a:	1800                	addi	s0,sp,48
    8000441c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000441e:	00850913          	addi	s2,a0,8
    80004422:	854a                	mv	a0,s2
    80004424:	ffffc097          	auipc	ra,0xffffc
    80004428:	7b2080e7          	jalr	1970(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000442c:	409c                	lw	a5,0(s1)
    8000442e:	ef99                	bnez	a5,8000444c <holdingsleep+0x3e>
    80004430:	4481                	li	s1,0
  release(&lk->lk);
    80004432:	854a                	mv	a0,s2
    80004434:	ffffd097          	auipc	ra,0xffffd
    80004438:	856080e7          	jalr	-1962(ra) # 80000c8a <release>
  return r;
}
    8000443c:	8526                	mv	a0,s1
    8000443e:	70a2                	ld	ra,40(sp)
    80004440:	7402                	ld	s0,32(sp)
    80004442:	64e2                	ld	s1,24(sp)
    80004444:	6942                	ld	s2,16(sp)
    80004446:	69a2                	ld	s3,8(sp)
    80004448:	6145                	addi	sp,sp,48
    8000444a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000444c:	0284a983          	lw	s3,40(s1)
    80004450:	ffffd097          	auipc	ra,0xffffd
    80004454:	55c080e7          	jalr	1372(ra) # 800019ac <myproc>
    80004458:	5904                	lw	s1,48(a0)
    8000445a:	413484b3          	sub	s1,s1,s3
    8000445e:	0014b493          	seqz	s1,s1
    80004462:	bfc1                	j	80004432 <holdingsleep+0x24>

0000000080004464 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004464:	1141                	addi	sp,sp,-16
    80004466:	e406                	sd	ra,8(sp)
    80004468:	e022                	sd	s0,0(sp)
    8000446a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000446c:	00004597          	auipc	a1,0x4
    80004470:	23c58593          	addi	a1,a1,572 # 800086a8 <syscalls+0x240>
    80004474:	0001d517          	auipc	a0,0x1d
    80004478:	81450513          	addi	a0,a0,-2028 # 80020c88 <ftable>
    8000447c:	ffffc097          	auipc	ra,0xffffc
    80004480:	6ca080e7          	jalr	1738(ra) # 80000b46 <initlock>
}
    80004484:	60a2                	ld	ra,8(sp)
    80004486:	6402                	ld	s0,0(sp)
    80004488:	0141                	addi	sp,sp,16
    8000448a:	8082                	ret

000000008000448c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000448c:	1101                	addi	sp,sp,-32
    8000448e:	ec06                	sd	ra,24(sp)
    80004490:	e822                	sd	s0,16(sp)
    80004492:	e426                	sd	s1,8(sp)
    80004494:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004496:	0001c517          	auipc	a0,0x1c
    8000449a:	7f250513          	addi	a0,a0,2034 # 80020c88 <ftable>
    8000449e:	ffffc097          	auipc	ra,0xffffc
    800044a2:	738080e7          	jalr	1848(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044a6:	0001c497          	auipc	s1,0x1c
    800044aa:	7fa48493          	addi	s1,s1,2042 # 80020ca0 <ftable+0x18>
    800044ae:	0001d717          	auipc	a4,0x1d
    800044b2:	79270713          	addi	a4,a4,1938 # 80021c40 <disk>
    if(f->ref == 0){
    800044b6:	40dc                	lw	a5,4(s1)
    800044b8:	cf99                	beqz	a5,800044d6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044ba:	02848493          	addi	s1,s1,40
    800044be:	fee49ce3          	bne	s1,a4,800044b6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044c2:	0001c517          	auipc	a0,0x1c
    800044c6:	7c650513          	addi	a0,a0,1990 # 80020c88 <ftable>
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	7c0080e7          	jalr	1984(ra) # 80000c8a <release>
  return 0;
    800044d2:	4481                	li	s1,0
    800044d4:	a819                	j	800044ea <filealloc+0x5e>
      f->ref = 1;
    800044d6:	4785                	li	a5,1
    800044d8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044da:	0001c517          	auipc	a0,0x1c
    800044de:	7ae50513          	addi	a0,a0,1966 # 80020c88 <ftable>
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	7a8080e7          	jalr	1960(ra) # 80000c8a <release>
}
    800044ea:	8526                	mv	a0,s1
    800044ec:	60e2                	ld	ra,24(sp)
    800044ee:	6442                	ld	s0,16(sp)
    800044f0:	64a2                	ld	s1,8(sp)
    800044f2:	6105                	addi	sp,sp,32
    800044f4:	8082                	ret

00000000800044f6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800044f6:	1101                	addi	sp,sp,-32
    800044f8:	ec06                	sd	ra,24(sp)
    800044fa:	e822                	sd	s0,16(sp)
    800044fc:	e426                	sd	s1,8(sp)
    800044fe:	1000                	addi	s0,sp,32
    80004500:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004502:	0001c517          	auipc	a0,0x1c
    80004506:	78650513          	addi	a0,a0,1926 # 80020c88 <ftable>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	6cc080e7          	jalr	1740(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004512:	40dc                	lw	a5,4(s1)
    80004514:	02f05263          	blez	a5,80004538 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004518:	2785                	addiw	a5,a5,1
    8000451a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000451c:	0001c517          	auipc	a0,0x1c
    80004520:	76c50513          	addi	a0,a0,1900 # 80020c88 <ftable>
    80004524:	ffffc097          	auipc	ra,0xffffc
    80004528:	766080e7          	jalr	1894(ra) # 80000c8a <release>
  return f;
}
    8000452c:	8526                	mv	a0,s1
    8000452e:	60e2                	ld	ra,24(sp)
    80004530:	6442                	ld	s0,16(sp)
    80004532:	64a2                	ld	s1,8(sp)
    80004534:	6105                	addi	sp,sp,32
    80004536:	8082                	ret
    panic("filedup");
    80004538:	00004517          	auipc	a0,0x4
    8000453c:	17850513          	addi	a0,a0,376 # 800086b0 <syscalls+0x248>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	000080e7          	jalr	ra # 80000540 <panic>

0000000080004548 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004548:	7139                	addi	sp,sp,-64
    8000454a:	fc06                	sd	ra,56(sp)
    8000454c:	f822                	sd	s0,48(sp)
    8000454e:	f426                	sd	s1,40(sp)
    80004550:	f04a                	sd	s2,32(sp)
    80004552:	ec4e                	sd	s3,24(sp)
    80004554:	e852                	sd	s4,16(sp)
    80004556:	e456                	sd	s5,8(sp)
    80004558:	0080                	addi	s0,sp,64
    8000455a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000455c:	0001c517          	auipc	a0,0x1c
    80004560:	72c50513          	addi	a0,a0,1836 # 80020c88 <ftable>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	672080e7          	jalr	1650(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000456c:	40dc                	lw	a5,4(s1)
    8000456e:	06f05163          	blez	a5,800045d0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004572:	37fd                	addiw	a5,a5,-1
    80004574:	0007871b          	sext.w	a4,a5
    80004578:	c0dc                	sw	a5,4(s1)
    8000457a:	06e04363          	bgtz	a4,800045e0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000457e:	0004a903          	lw	s2,0(s1)
    80004582:	0094ca83          	lbu	s5,9(s1)
    80004586:	0104ba03          	ld	s4,16(s1)
    8000458a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000458e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004592:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004596:	0001c517          	auipc	a0,0x1c
    8000459a:	6f250513          	addi	a0,a0,1778 # 80020c88 <ftable>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	6ec080e7          	jalr	1772(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800045a6:	4785                	li	a5,1
    800045a8:	04f90d63          	beq	s2,a5,80004602 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045ac:	3979                	addiw	s2,s2,-2
    800045ae:	4785                	li	a5,1
    800045b0:	0527e063          	bltu	a5,s2,800045f0 <fileclose+0xa8>
    begin_op();
    800045b4:	00000097          	auipc	ra,0x0
    800045b8:	acc080e7          	jalr	-1332(ra) # 80004080 <begin_op>
    iput(ff.ip);
    800045bc:	854e                	mv	a0,s3
    800045be:	fffff097          	auipc	ra,0xfffff
    800045c2:	2b0080e7          	jalr	688(ra) # 8000386e <iput>
    end_op();
    800045c6:	00000097          	auipc	ra,0x0
    800045ca:	b38080e7          	jalr	-1224(ra) # 800040fe <end_op>
    800045ce:	a00d                	j	800045f0 <fileclose+0xa8>
    panic("fileclose");
    800045d0:	00004517          	auipc	a0,0x4
    800045d4:	0e850513          	addi	a0,a0,232 # 800086b8 <syscalls+0x250>
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	f68080e7          	jalr	-152(ra) # 80000540 <panic>
    release(&ftable.lock);
    800045e0:	0001c517          	auipc	a0,0x1c
    800045e4:	6a850513          	addi	a0,a0,1704 # 80020c88 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	6a2080e7          	jalr	1698(ra) # 80000c8a <release>
  }
}
    800045f0:	70e2                	ld	ra,56(sp)
    800045f2:	7442                	ld	s0,48(sp)
    800045f4:	74a2                	ld	s1,40(sp)
    800045f6:	7902                	ld	s2,32(sp)
    800045f8:	69e2                	ld	s3,24(sp)
    800045fa:	6a42                	ld	s4,16(sp)
    800045fc:	6aa2                	ld	s5,8(sp)
    800045fe:	6121                	addi	sp,sp,64
    80004600:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004602:	85d6                	mv	a1,s5
    80004604:	8552                	mv	a0,s4
    80004606:	00000097          	auipc	ra,0x0
    8000460a:	34c080e7          	jalr	844(ra) # 80004952 <pipeclose>
    8000460e:	b7cd                	j	800045f0 <fileclose+0xa8>

0000000080004610 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004610:	715d                	addi	sp,sp,-80
    80004612:	e486                	sd	ra,72(sp)
    80004614:	e0a2                	sd	s0,64(sp)
    80004616:	fc26                	sd	s1,56(sp)
    80004618:	f84a                	sd	s2,48(sp)
    8000461a:	f44e                	sd	s3,40(sp)
    8000461c:	0880                	addi	s0,sp,80
    8000461e:	84aa                	mv	s1,a0
    80004620:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004622:	ffffd097          	auipc	ra,0xffffd
    80004626:	38a080e7          	jalr	906(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000462a:	409c                	lw	a5,0(s1)
    8000462c:	37f9                	addiw	a5,a5,-2
    8000462e:	4705                	li	a4,1
    80004630:	04f76763          	bltu	a4,a5,8000467e <filestat+0x6e>
    80004634:	892a                	mv	s2,a0
    ilock(f->ip);
    80004636:	6c88                	ld	a0,24(s1)
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	07c080e7          	jalr	124(ra) # 800036b4 <ilock>
    stati(f->ip, &st);
    80004640:	fb840593          	addi	a1,s0,-72
    80004644:	6c88                	ld	a0,24(s1)
    80004646:	fffff097          	auipc	ra,0xfffff
    8000464a:	2f8080e7          	jalr	760(ra) # 8000393e <stati>
    iunlock(f->ip);
    8000464e:	6c88                	ld	a0,24(s1)
    80004650:	fffff097          	auipc	ra,0xfffff
    80004654:	126080e7          	jalr	294(ra) # 80003776 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004658:	46e1                	li	a3,24
    8000465a:	fb840613          	addi	a2,s0,-72
    8000465e:	85ce                	mv	a1,s3
    80004660:	05093503          	ld	a0,80(s2)
    80004664:	ffffd097          	auipc	ra,0xffffd
    80004668:	008080e7          	jalr	8(ra) # 8000166c <copyout>
    8000466c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004670:	60a6                	ld	ra,72(sp)
    80004672:	6406                	ld	s0,64(sp)
    80004674:	74e2                	ld	s1,56(sp)
    80004676:	7942                	ld	s2,48(sp)
    80004678:	79a2                	ld	s3,40(sp)
    8000467a:	6161                	addi	sp,sp,80
    8000467c:	8082                	ret
  return -1;
    8000467e:	557d                	li	a0,-1
    80004680:	bfc5                	j	80004670 <filestat+0x60>

0000000080004682 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004682:	7179                	addi	sp,sp,-48
    80004684:	f406                	sd	ra,40(sp)
    80004686:	f022                	sd	s0,32(sp)
    80004688:	ec26                	sd	s1,24(sp)
    8000468a:	e84a                	sd	s2,16(sp)
    8000468c:	e44e                	sd	s3,8(sp)
    8000468e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004690:	00854783          	lbu	a5,8(a0)
    80004694:	c3d5                	beqz	a5,80004738 <fileread+0xb6>
    80004696:	84aa                	mv	s1,a0
    80004698:	89ae                	mv	s3,a1
    8000469a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000469c:	411c                	lw	a5,0(a0)
    8000469e:	4705                	li	a4,1
    800046a0:	04e78963          	beq	a5,a4,800046f2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046a4:	470d                	li	a4,3
    800046a6:	04e78d63          	beq	a5,a4,80004700 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046aa:	4709                	li	a4,2
    800046ac:	06e79e63          	bne	a5,a4,80004728 <fileread+0xa6>
    ilock(f->ip);
    800046b0:	6d08                	ld	a0,24(a0)
    800046b2:	fffff097          	auipc	ra,0xfffff
    800046b6:	002080e7          	jalr	2(ra) # 800036b4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046ba:	874a                	mv	a4,s2
    800046bc:	5094                	lw	a3,32(s1)
    800046be:	864e                	mv	a2,s3
    800046c0:	4585                	li	a1,1
    800046c2:	6c88                	ld	a0,24(s1)
    800046c4:	fffff097          	auipc	ra,0xfffff
    800046c8:	2a4080e7          	jalr	676(ra) # 80003968 <readi>
    800046cc:	892a                	mv	s2,a0
    800046ce:	00a05563          	blez	a0,800046d8 <fileread+0x56>
      f->off += r;
    800046d2:	509c                	lw	a5,32(s1)
    800046d4:	9fa9                	addw	a5,a5,a0
    800046d6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046d8:	6c88                	ld	a0,24(s1)
    800046da:	fffff097          	auipc	ra,0xfffff
    800046de:	09c080e7          	jalr	156(ra) # 80003776 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046e2:	854a                	mv	a0,s2
    800046e4:	70a2                	ld	ra,40(sp)
    800046e6:	7402                	ld	s0,32(sp)
    800046e8:	64e2                	ld	s1,24(sp)
    800046ea:	6942                	ld	s2,16(sp)
    800046ec:	69a2                	ld	s3,8(sp)
    800046ee:	6145                	addi	sp,sp,48
    800046f0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800046f2:	6908                	ld	a0,16(a0)
    800046f4:	00000097          	auipc	ra,0x0
    800046f8:	3c6080e7          	jalr	966(ra) # 80004aba <piperead>
    800046fc:	892a                	mv	s2,a0
    800046fe:	b7d5                	j	800046e2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004700:	02451783          	lh	a5,36(a0)
    80004704:	03079693          	slli	a3,a5,0x30
    80004708:	92c1                	srli	a3,a3,0x30
    8000470a:	4725                	li	a4,9
    8000470c:	02d76863          	bltu	a4,a3,8000473c <fileread+0xba>
    80004710:	0792                	slli	a5,a5,0x4
    80004712:	0001c717          	auipc	a4,0x1c
    80004716:	4d670713          	addi	a4,a4,1238 # 80020be8 <devsw>
    8000471a:	97ba                	add	a5,a5,a4
    8000471c:	639c                	ld	a5,0(a5)
    8000471e:	c38d                	beqz	a5,80004740 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004720:	4505                	li	a0,1
    80004722:	9782                	jalr	a5
    80004724:	892a                	mv	s2,a0
    80004726:	bf75                	j	800046e2 <fileread+0x60>
    panic("fileread");
    80004728:	00004517          	auipc	a0,0x4
    8000472c:	fa050513          	addi	a0,a0,-96 # 800086c8 <syscalls+0x260>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	e10080e7          	jalr	-496(ra) # 80000540 <panic>
    return -1;
    80004738:	597d                	li	s2,-1
    8000473a:	b765                	j	800046e2 <fileread+0x60>
      return -1;
    8000473c:	597d                	li	s2,-1
    8000473e:	b755                	j	800046e2 <fileread+0x60>
    80004740:	597d                	li	s2,-1
    80004742:	b745                	j	800046e2 <fileread+0x60>

0000000080004744 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004744:	715d                	addi	sp,sp,-80
    80004746:	e486                	sd	ra,72(sp)
    80004748:	e0a2                	sd	s0,64(sp)
    8000474a:	fc26                	sd	s1,56(sp)
    8000474c:	f84a                	sd	s2,48(sp)
    8000474e:	f44e                	sd	s3,40(sp)
    80004750:	f052                	sd	s4,32(sp)
    80004752:	ec56                	sd	s5,24(sp)
    80004754:	e85a                	sd	s6,16(sp)
    80004756:	e45e                	sd	s7,8(sp)
    80004758:	e062                	sd	s8,0(sp)
    8000475a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000475c:	00954783          	lbu	a5,9(a0)
    80004760:	10078663          	beqz	a5,8000486c <filewrite+0x128>
    80004764:	892a                	mv	s2,a0
    80004766:	8b2e                	mv	s6,a1
    80004768:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000476a:	411c                	lw	a5,0(a0)
    8000476c:	4705                	li	a4,1
    8000476e:	02e78263          	beq	a5,a4,80004792 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004772:	470d                	li	a4,3
    80004774:	02e78663          	beq	a5,a4,800047a0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004778:	4709                	li	a4,2
    8000477a:	0ee79163          	bne	a5,a4,8000485c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000477e:	0ac05d63          	blez	a2,80004838 <filewrite+0xf4>
    int i = 0;
    80004782:	4981                	li	s3,0
    80004784:	6b85                	lui	s7,0x1
    80004786:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000478a:	6c05                	lui	s8,0x1
    8000478c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004790:	a861                	j	80004828 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004792:	6908                	ld	a0,16(a0)
    80004794:	00000097          	auipc	ra,0x0
    80004798:	22e080e7          	jalr	558(ra) # 800049c2 <pipewrite>
    8000479c:	8a2a                	mv	s4,a0
    8000479e:	a045                	j	8000483e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047a0:	02451783          	lh	a5,36(a0)
    800047a4:	03079693          	slli	a3,a5,0x30
    800047a8:	92c1                	srli	a3,a3,0x30
    800047aa:	4725                	li	a4,9
    800047ac:	0cd76263          	bltu	a4,a3,80004870 <filewrite+0x12c>
    800047b0:	0792                	slli	a5,a5,0x4
    800047b2:	0001c717          	auipc	a4,0x1c
    800047b6:	43670713          	addi	a4,a4,1078 # 80020be8 <devsw>
    800047ba:	97ba                	add	a5,a5,a4
    800047bc:	679c                	ld	a5,8(a5)
    800047be:	cbdd                	beqz	a5,80004874 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800047c0:	4505                	li	a0,1
    800047c2:	9782                	jalr	a5
    800047c4:	8a2a                	mv	s4,a0
    800047c6:	a8a5                	j	8000483e <filewrite+0xfa>
    800047c8:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	8b4080e7          	jalr	-1868(ra) # 80004080 <begin_op>
      ilock(f->ip);
    800047d4:	01893503          	ld	a0,24(s2)
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	edc080e7          	jalr	-292(ra) # 800036b4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047e0:	8756                	mv	a4,s5
    800047e2:	02092683          	lw	a3,32(s2)
    800047e6:	01698633          	add	a2,s3,s6
    800047ea:	4585                	li	a1,1
    800047ec:	01893503          	ld	a0,24(s2)
    800047f0:	fffff097          	auipc	ra,0xfffff
    800047f4:	270080e7          	jalr	624(ra) # 80003a60 <writei>
    800047f8:	84aa                	mv	s1,a0
    800047fa:	00a05763          	blez	a0,80004808 <filewrite+0xc4>
        f->off += r;
    800047fe:	02092783          	lw	a5,32(s2)
    80004802:	9fa9                	addw	a5,a5,a0
    80004804:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004808:	01893503          	ld	a0,24(s2)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	f6a080e7          	jalr	-150(ra) # 80003776 <iunlock>
      end_op();
    80004814:	00000097          	auipc	ra,0x0
    80004818:	8ea080e7          	jalr	-1814(ra) # 800040fe <end_op>

      if(r != n1){
    8000481c:	009a9f63          	bne	s5,s1,8000483a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004820:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004824:	0149db63          	bge	s3,s4,8000483a <filewrite+0xf6>
      int n1 = n - i;
    80004828:	413a04bb          	subw	s1,s4,s3
    8000482c:	0004879b          	sext.w	a5,s1
    80004830:	f8fbdce3          	bge	s7,a5,800047c8 <filewrite+0x84>
    80004834:	84e2                	mv	s1,s8
    80004836:	bf49                	j	800047c8 <filewrite+0x84>
    int i = 0;
    80004838:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000483a:	013a1f63          	bne	s4,s3,80004858 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000483e:	8552                	mv	a0,s4
    80004840:	60a6                	ld	ra,72(sp)
    80004842:	6406                	ld	s0,64(sp)
    80004844:	74e2                	ld	s1,56(sp)
    80004846:	7942                	ld	s2,48(sp)
    80004848:	79a2                	ld	s3,40(sp)
    8000484a:	7a02                	ld	s4,32(sp)
    8000484c:	6ae2                	ld	s5,24(sp)
    8000484e:	6b42                	ld	s6,16(sp)
    80004850:	6ba2                	ld	s7,8(sp)
    80004852:	6c02                	ld	s8,0(sp)
    80004854:	6161                	addi	sp,sp,80
    80004856:	8082                	ret
    ret = (i == n ? n : -1);
    80004858:	5a7d                	li	s4,-1
    8000485a:	b7d5                	j	8000483e <filewrite+0xfa>
    panic("filewrite");
    8000485c:	00004517          	auipc	a0,0x4
    80004860:	e7c50513          	addi	a0,a0,-388 # 800086d8 <syscalls+0x270>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	cdc080e7          	jalr	-804(ra) # 80000540 <panic>
    return -1;
    8000486c:	5a7d                	li	s4,-1
    8000486e:	bfc1                	j	8000483e <filewrite+0xfa>
      return -1;
    80004870:	5a7d                	li	s4,-1
    80004872:	b7f1                	j	8000483e <filewrite+0xfa>
    80004874:	5a7d                	li	s4,-1
    80004876:	b7e1                	j	8000483e <filewrite+0xfa>

0000000080004878 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004878:	7179                	addi	sp,sp,-48
    8000487a:	f406                	sd	ra,40(sp)
    8000487c:	f022                	sd	s0,32(sp)
    8000487e:	ec26                	sd	s1,24(sp)
    80004880:	e84a                	sd	s2,16(sp)
    80004882:	e44e                	sd	s3,8(sp)
    80004884:	e052                	sd	s4,0(sp)
    80004886:	1800                	addi	s0,sp,48
    80004888:	84aa                	mv	s1,a0
    8000488a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000488c:	0005b023          	sd	zero,0(a1)
    80004890:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004894:	00000097          	auipc	ra,0x0
    80004898:	bf8080e7          	jalr	-1032(ra) # 8000448c <filealloc>
    8000489c:	e088                	sd	a0,0(s1)
    8000489e:	c551                	beqz	a0,8000492a <pipealloc+0xb2>
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	bec080e7          	jalr	-1044(ra) # 8000448c <filealloc>
    800048a8:	00aa3023          	sd	a0,0(s4)
    800048ac:	c92d                	beqz	a0,8000491e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048ae:	ffffc097          	auipc	ra,0xffffc
    800048b2:	238080e7          	jalr	568(ra) # 80000ae6 <kalloc>
    800048b6:	892a                	mv	s2,a0
    800048b8:	c125                	beqz	a0,80004918 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048ba:	4985                	li	s3,1
    800048bc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048c0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048c4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048c8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800048cc:	00004597          	auipc	a1,0x4
    800048d0:	e1c58593          	addi	a1,a1,-484 # 800086e8 <syscalls+0x280>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	272080e7          	jalr	626(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800048dc:	609c                	ld	a5,0(s1)
    800048de:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800048e2:	609c                	ld	a5,0(s1)
    800048e4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800048e8:	609c                	ld	a5,0(s1)
    800048ea:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800048ee:	609c                	ld	a5,0(s1)
    800048f0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800048f4:	000a3783          	ld	a5,0(s4)
    800048f8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800048fc:	000a3783          	ld	a5,0(s4)
    80004900:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004904:	000a3783          	ld	a5,0(s4)
    80004908:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000490c:	000a3783          	ld	a5,0(s4)
    80004910:	0127b823          	sd	s2,16(a5)
  return 0;
    80004914:	4501                	li	a0,0
    80004916:	a025                	j	8000493e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004918:	6088                	ld	a0,0(s1)
    8000491a:	e501                	bnez	a0,80004922 <pipealloc+0xaa>
    8000491c:	a039                	j	8000492a <pipealloc+0xb2>
    8000491e:	6088                	ld	a0,0(s1)
    80004920:	c51d                	beqz	a0,8000494e <pipealloc+0xd6>
    fileclose(*f0);
    80004922:	00000097          	auipc	ra,0x0
    80004926:	c26080e7          	jalr	-986(ra) # 80004548 <fileclose>
  if(*f1)
    8000492a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000492e:	557d                	li	a0,-1
  if(*f1)
    80004930:	c799                	beqz	a5,8000493e <pipealloc+0xc6>
    fileclose(*f1);
    80004932:	853e                	mv	a0,a5
    80004934:	00000097          	auipc	ra,0x0
    80004938:	c14080e7          	jalr	-1004(ra) # 80004548 <fileclose>
  return -1;
    8000493c:	557d                	li	a0,-1
}
    8000493e:	70a2                	ld	ra,40(sp)
    80004940:	7402                	ld	s0,32(sp)
    80004942:	64e2                	ld	s1,24(sp)
    80004944:	6942                	ld	s2,16(sp)
    80004946:	69a2                	ld	s3,8(sp)
    80004948:	6a02                	ld	s4,0(sp)
    8000494a:	6145                	addi	sp,sp,48
    8000494c:	8082                	ret
  return -1;
    8000494e:	557d                	li	a0,-1
    80004950:	b7fd                	j	8000493e <pipealloc+0xc6>

0000000080004952 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004952:	1101                	addi	sp,sp,-32
    80004954:	ec06                	sd	ra,24(sp)
    80004956:	e822                	sd	s0,16(sp)
    80004958:	e426                	sd	s1,8(sp)
    8000495a:	e04a                	sd	s2,0(sp)
    8000495c:	1000                	addi	s0,sp,32
    8000495e:	84aa                	mv	s1,a0
    80004960:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004962:	ffffc097          	auipc	ra,0xffffc
    80004966:	274080e7          	jalr	628(ra) # 80000bd6 <acquire>
  if(writable){
    8000496a:	02090d63          	beqz	s2,800049a4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000496e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004972:	21848513          	addi	a0,s1,536
    80004976:	ffffd097          	auipc	ra,0xffffd
    8000497a:	742080e7          	jalr	1858(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000497e:	2204b783          	ld	a5,544(s1)
    80004982:	eb95                	bnez	a5,800049b6 <pipeclose+0x64>
    release(&pi->lock);
    80004984:	8526                	mv	a0,s1
    80004986:	ffffc097          	auipc	ra,0xffffc
    8000498a:	304080e7          	jalr	772(ra) # 80000c8a <release>
    kfree((char*)pi);
    8000498e:	8526                	mv	a0,s1
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	058080e7          	jalr	88(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004998:	60e2                	ld	ra,24(sp)
    8000499a:	6442                	ld	s0,16(sp)
    8000499c:	64a2                	ld	s1,8(sp)
    8000499e:	6902                	ld	s2,0(sp)
    800049a0:	6105                	addi	sp,sp,32
    800049a2:	8082                	ret
    pi->readopen = 0;
    800049a4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049a8:	21c48513          	addi	a0,s1,540
    800049ac:	ffffd097          	auipc	ra,0xffffd
    800049b0:	70c080e7          	jalr	1804(ra) # 800020b8 <wakeup>
    800049b4:	b7e9                	j	8000497e <pipeclose+0x2c>
    release(&pi->lock);
    800049b6:	8526                	mv	a0,s1
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	2d2080e7          	jalr	722(ra) # 80000c8a <release>
}
    800049c0:	bfe1                	j	80004998 <pipeclose+0x46>

00000000800049c2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049c2:	711d                	addi	sp,sp,-96
    800049c4:	ec86                	sd	ra,88(sp)
    800049c6:	e8a2                	sd	s0,80(sp)
    800049c8:	e4a6                	sd	s1,72(sp)
    800049ca:	e0ca                	sd	s2,64(sp)
    800049cc:	fc4e                	sd	s3,56(sp)
    800049ce:	f852                	sd	s4,48(sp)
    800049d0:	f456                	sd	s5,40(sp)
    800049d2:	f05a                	sd	s6,32(sp)
    800049d4:	ec5e                	sd	s7,24(sp)
    800049d6:	e862                	sd	s8,16(sp)
    800049d8:	1080                	addi	s0,sp,96
    800049da:	84aa                	mv	s1,a0
    800049dc:	8aae                	mv	s5,a1
    800049de:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800049e0:	ffffd097          	auipc	ra,0xffffd
    800049e4:	fcc080e7          	jalr	-52(ra) # 800019ac <myproc>
    800049e8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800049ea:	8526                	mv	a0,s1
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	1ea080e7          	jalr	490(ra) # 80000bd6 <acquire>
  while(i < n){
    800049f4:	0b405663          	blez	s4,80004aa0 <pipewrite+0xde>
  int i = 0;
    800049f8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800049fa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800049fc:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a00:	21c48b93          	addi	s7,s1,540
    80004a04:	a089                	j	80004a46 <pipewrite+0x84>
      release(&pi->lock);
    80004a06:	8526                	mv	a0,s1
    80004a08:	ffffc097          	auipc	ra,0xffffc
    80004a0c:	282080e7          	jalr	642(ra) # 80000c8a <release>
      return -1;
    80004a10:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a12:	854a                	mv	a0,s2
    80004a14:	60e6                	ld	ra,88(sp)
    80004a16:	6446                	ld	s0,80(sp)
    80004a18:	64a6                	ld	s1,72(sp)
    80004a1a:	6906                	ld	s2,64(sp)
    80004a1c:	79e2                	ld	s3,56(sp)
    80004a1e:	7a42                	ld	s4,48(sp)
    80004a20:	7aa2                	ld	s5,40(sp)
    80004a22:	7b02                	ld	s6,32(sp)
    80004a24:	6be2                	ld	s7,24(sp)
    80004a26:	6c42                	ld	s8,16(sp)
    80004a28:	6125                	addi	sp,sp,96
    80004a2a:	8082                	ret
      wakeup(&pi->nread);
    80004a2c:	8562                	mv	a0,s8
    80004a2e:	ffffd097          	auipc	ra,0xffffd
    80004a32:	68a080e7          	jalr	1674(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a36:	85a6                	mv	a1,s1
    80004a38:	855e                	mv	a0,s7
    80004a3a:	ffffd097          	auipc	ra,0xffffd
    80004a3e:	61a080e7          	jalr	1562(ra) # 80002054 <sleep>
  while(i < n){
    80004a42:	07495063          	bge	s2,s4,80004aa2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a46:	2204a783          	lw	a5,544(s1)
    80004a4a:	dfd5                	beqz	a5,80004a06 <pipewrite+0x44>
    80004a4c:	854e                	mv	a0,s3
    80004a4e:	ffffe097          	auipc	ra,0xffffe
    80004a52:	8ae080e7          	jalr	-1874(ra) # 800022fc <killed>
    80004a56:	f945                	bnez	a0,80004a06 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004a58:	2184a783          	lw	a5,536(s1)
    80004a5c:	21c4a703          	lw	a4,540(s1)
    80004a60:	2007879b          	addiw	a5,a5,512
    80004a64:	fcf704e3          	beq	a4,a5,80004a2c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a68:	4685                	li	a3,1
    80004a6a:	01590633          	add	a2,s2,s5
    80004a6e:	faf40593          	addi	a1,s0,-81
    80004a72:	0509b503          	ld	a0,80(s3)
    80004a76:	ffffd097          	auipc	ra,0xffffd
    80004a7a:	c82080e7          	jalr	-894(ra) # 800016f8 <copyin>
    80004a7e:	03650263          	beq	a0,s6,80004aa2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a82:	21c4a783          	lw	a5,540(s1)
    80004a86:	0017871b          	addiw	a4,a5,1
    80004a8a:	20e4ae23          	sw	a4,540(s1)
    80004a8e:	1ff7f793          	andi	a5,a5,511
    80004a92:	97a6                	add	a5,a5,s1
    80004a94:	faf44703          	lbu	a4,-81(s0)
    80004a98:	00e78c23          	sb	a4,24(a5)
      i++;
    80004a9c:	2905                	addiw	s2,s2,1
    80004a9e:	b755                	j	80004a42 <pipewrite+0x80>
  int i = 0;
    80004aa0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004aa2:	21848513          	addi	a0,s1,536
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	612080e7          	jalr	1554(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	1da080e7          	jalr	474(ra) # 80000c8a <release>
  return i;
    80004ab8:	bfa9                	j	80004a12 <pipewrite+0x50>

0000000080004aba <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004aba:	715d                	addi	sp,sp,-80
    80004abc:	e486                	sd	ra,72(sp)
    80004abe:	e0a2                	sd	s0,64(sp)
    80004ac0:	fc26                	sd	s1,56(sp)
    80004ac2:	f84a                	sd	s2,48(sp)
    80004ac4:	f44e                	sd	s3,40(sp)
    80004ac6:	f052                	sd	s4,32(sp)
    80004ac8:	ec56                	sd	s5,24(sp)
    80004aca:	e85a                	sd	s6,16(sp)
    80004acc:	0880                	addi	s0,sp,80
    80004ace:	84aa                	mv	s1,a0
    80004ad0:	892e                	mv	s2,a1
    80004ad2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ad4:	ffffd097          	auipc	ra,0xffffd
    80004ad8:	ed8080e7          	jalr	-296(ra) # 800019ac <myproc>
    80004adc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ade:	8526                	mv	a0,s1
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	0f6080e7          	jalr	246(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ae8:	2184a703          	lw	a4,536(s1)
    80004aec:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004af0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004af4:	02f71763          	bne	a4,a5,80004b22 <piperead+0x68>
    80004af8:	2244a783          	lw	a5,548(s1)
    80004afc:	c39d                	beqz	a5,80004b22 <piperead+0x68>
    if(killed(pr)){
    80004afe:	8552                	mv	a0,s4
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	7fc080e7          	jalr	2044(ra) # 800022fc <killed>
    80004b08:	e949                	bnez	a0,80004b9a <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b0a:	85a6                	mv	a1,s1
    80004b0c:	854e                	mv	a0,s3
    80004b0e:	ffffd097          	auipc	ra,0xffffd
    80004b12:	546080e7          	jalr	1350(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b16:	2184a703          	lw	a4,536(s1)
    80004b1a:	21c4a783          	lw	a5,540(s1)
    80004b1e:	fcf70de3          	beq	a4,a5,80004af8 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b22:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b24:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b26:	05505463          	blez	s5,80004b6e <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b2a:	2184a783          	lw	a5,536(s1)
    80004b2e:	21c4a703          	lw	a4,540(s1)
    80004b32:	02f70e63          	beq	a4,a5,80004b6e <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b36:	0017871b          	addiw	a4,a5,1
    80004b3a:	20e4ac23          	sw	a4,536(s1)
    80004b3e:	1ff7f793          	andi	a5,a5,511
    80004b42:	97a6                	add	a5,a5,s1
    80004b44:	0187c783          	lbu	a5,24(a5)
    80004b48:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b4c:	4685                	li	a3,1
    80004b4e:	fbf40613          	addi	a2,s0,-65
    80004b52:	85ca                	mv	a1,s2
    80004b54:	050a3503          	ld	a0,80(s4)
    80004b58:	ffffd097          	auipc	ra,0xffffd
    80004b5c:	b14080e7          	jalr	-1260(ra) # 8000166c <copyout>
    80004b60:	01650763          	beq	a0,s6,80004b6e <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b64:	2985                	addiw	s3,s3,1
    80004b66:	0905                	addi	s2,s2,1
    80004b68:	fd3a91e3          	bne	s5,s3,80004b2a <piperead+0x70>
    80004b6c:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004b6e:	21c48513          	addi	a0,s1,540
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	546080e7          	jalr	1350(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004b7a:	8526                	mv	a0,s1
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	10e080e7          	jalr	270(ra) # 80000c8a <release>
  return i;
}
    80004b84:	854e                	mv	a0,s3
    80004b86:	60a6                	ld	ra,72(sp)
    80004b88:	6406                	ld	s0,64(sp)
    80004b8a:	74e2                	ld	s1,56(sp)
    80004b8c:	7942                	ld	s2,48(sp)
    80004b8e:	79a2                	ld	s3,40(sp)
    80004b90:	7a02                	ld	s4,32(sp)
    80004b92:	6ae2                	ld	s5,24(sp)
    80004b94:	6b42                	ld	s6,16(sp)
    80004b96:	6161                	addi	sp,sp,80
    80004b98:	8082                	ret
      release(&pi->lock);
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	ffffc097          	auipc	ra,0xffffc
    80004ba0:	0ee080e7          	jalr	238(ra) # 80000c8a <release>
      return -1;
    80004ba4:	59fd                	li	s3,-1
    80004ba6:	bff9                	j	80004b84 <piperead+0xca>

0000000080004ba8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ba8:	1141                	addi	sp,sp,-16
    80004baa:	e422                	sd	s0,8(sp)
    80004bac:	0800                	addi	s0,sp,16
    80004bae:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bb0:	8905                	andi	a0,a0,1
    80004bb2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004bb4:	8b89                	andi	a5,a5,2
    80004bb6:	c399                	beqz	a5,80004bbc <flags2perm+0x14>
      perm |= PTE_W;
    80004bb8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004bbc:	6422                	ld	s0,8(sp)
    80004bbe:	0141                	addi	sp,sp,16
    80004bc0:	8082                	ret

0000000080004bc2 <exec>:

int
exec(char *path, char **argv)
{
    80004bc2:	de010113          	addi	sp,sp,-544
    80004bc6:	20113c23          	sd	ra,536(sp)
    80004bca:	20813823          	sd	s0,528(sp)
    80004bce:	20913423          	sd	s1,520(sp)
    80004bd2:	21213023          	sd	s2,512(sp)
    80004bd6:	ffce                	sd	s3,504(sp)
    80004bd8:	fbd2                	sd	s4,496(sp)
    80004bda:	f7d6                	sd	s5,488(sp)
    80004bdc:	f3da                	sd	s6,480(sp)
    80004bde:	efde                	sd	s7,472(sp)
    80004be0:	ebe2                	sd	s8,464(sp)
    80004be2:	e7e6                	sd	s9,456(sp)
    80004be4:	e3ea                	sd	s10,448(sp)
    80004be6:	ff6e                	sd	s11,440(sp)
    80004be8:	1400                	addi	s0,sp,544
    80004bea:	892a                	mv	s2,a0
    80004bec:	dea43423          	sd	a0,-536(s0)
    80004bf0:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004bf4:	ffffd097          	auipc	ra,0xffffd
    80004bf8:	db8080e7          	jalr	-584(ra) # 800019ac <myproc>
    80004bfc:	84aa                	mv	s1,a0

  begin_op();
    80004bfe:	fffff097          	auipc	ra,0xfffff
    80004c02:	482080e7          	jalr	1154(ra) # 80004080 <begin_op>

  if((ip = namei(path)) == 0){
    80004c06:	854a                	mv	a0,s2
    80004c08:	fffff097          	auipc	ra,0xfffff
    80004c0c:	258080e7          	jalr	600(ra) # 80003e60 <namei>
    80004c10:	c93d                	beqz	a0,80004c86 <exec+0xc4>
    80004c12:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c14:	fffff097          	auipc	ra,0xfffff
    80004c18:	aa0080e7          	jalr	-1376(ra) # 800036b4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c1c:	04000713          	li	a4,64
    80004c20:	4681                	li	a3,0
    80004c22:	e5040613          	addi	a2,s0,-432
    80004c26:	4581                	li	a1,0
    80004c28:	8556                	mv	a0,s5
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	d3e080e7          	jalr	-706(ra) # 80003968 <readi>
    80004c32:	04000793          	li	a5,64
    80004c36:	00f51a63          	bne	a0,a5,80004c4a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c3a:	e5042703          	lw	a4,-432(s0)
    80004c3e:	464c47b7          	lui	a5,0x464c4
    80004c42:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c46:	04f70663          	beq	a4,a5,80004c92 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c4a:	8556                	mv	a0,s5
    80004c4c:	fffff097          	auipc	ra,0xfffff
    80004c50:	cca080e7          	jalr	-822(ra) # 80003916 <iunlockput>
    end_op();
    80004c54:	fffff097          	auipc	ra,0xfffff
    80004c58:	4aa080e7          	jalr	1194(ra) # 800040fe <end_op>
  }
  return -1;
    80004c5c:	557d                	li	a0,-1
}
    80004c5e:	21813083          	ld	ra,536(sp)
    80004c62:	21013403          	ld	s0,528(sp)
    80004c66:	20813483          	ld	s1,520(sp)
    80004c6a:	20013903          	ld	s2,512(sp)
    80004c6e:	79fe                	ld	s3,504(sp)
    80004c70:	7a5e                	ld	s4,496(sp)
    80004c72:	7abe                	ld	s5,488(sp)
    80004c74:	7b1e                	ld	s6,480(sp)
    80004c76:	6bfe                	ld	s7,472(sp)
    80004c78:	6c5e                	ld	s8,464(sp)
    80004c7a:	6cbe                	ld	s9,456(sp)
    80004c7c:	6d1e                	ld	s10,448(sp)
    80004c7e:	7dfa                	ld	s11,440(sp)
    80004c80:	22010113          	addi	sp,sp,544
    80004c84:	8082                	ret
    end_op();
    80004c86:	fffff097          	auipc	ra,0xfffff
    80004c8a:	478080e7          	jalr	1144(ra) # 800040fe <end_op>
    return -1;
    80004c8e:	557d                	li	a0,-1
    80004c90:	b7f9                	j	80004c5e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004c92:	8526                	mv	a0,s1
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	ddc080e7          	jalr	-548(ra) # 80001a70 <proc_pagetable>
    80004c9c:	8b2a                	mv	s6,a0
    80004c9e:	d555                	beqz	a0,80004c4a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ca0:	e7042783          	lw	a5,-400(s0)
    80004ca4:	e8845703          	lhu	a4,-376(s0)
    80004ca8:	c735                	beqz	a4,80004d14 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004caa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cac:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cb0:	6a05                	lui	s4,0x1
    80004cb2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cb6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004cba:	6d85                	lui	s11,0x1
    80004cbc:	7d7d                	lui	s10,0xfffff
    80004cbe:	ac3d                	j	80004efc <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cc0:	00004517          	auipc	a0,0x4
    80004cc4:	a3050513          	addi	a0,a0,-1488 # 800086f0 <syscalls+0x288>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	878080e7          	jalr	-1928(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cd0:	874a                	mv	a4,s2
    80004cd2:	009c86bb          	addw	a3,s9,s1
    80004cd6:	4581                	li	a1,0
    80004cd8:	8556                	mv	a0,s5
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	c8e080e7          	jalr	-882(ra) # 80003968 <readi>
    80004ce2:	2501                	sext.w	a0,a0
    80004ce4:	1aa91963          	bne	s2,a0,80004e96 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004ce8:	009d84bb          	addw	s1,s11,s1
    80004cec:	013d09bb          	addw	s3,s10,s3
    80004cf0:	1f74f663          	bgeu	s1,s7,80004edc <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004cf4:	02049593          	slli	a1,s1,0x20
    80004cf8:	9181                	srli	a1,a1,0x20
    80004cfa:	95e2                	add	a1,a1,s8
    80004cfc:	855a                	mv	a0,s6
    80004cfe:	ffffc097          	auipc	ra,0xffffc
    80004d02:	35e080e7          	jalr	862(ra) # 8000105c <walkaddr>
    80004d06:	862a                	mv	a2,a0
    if(pa == 0)
    80004d08:	dd45                	beqz	a0,80004cc0 <exec+0xfe>
      n = PGSIZE;
    80004d0a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d0c:	fd49f2e3          	bgeu	s3,s4,80004cd0 <exec+0x10e>
      n = sz - i;
    80004d10:	894e                	mv	s2,s3
    80004d12:	bf7d                	j	80004cd0 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d14:	4901                	li	s2,0
  iunlockput(ip);
    80004d16:	8556                	mv	a0,s5
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	bfe080e7          	jalr	-1026(ra) # 80003916 <iunlockput>
  end_op();
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	3de080e7          	jalr	990(ra) # 800040fe <end_op>
  p = myproc();
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	c84080e7          	jalr	-892(ra) # 800019ac <myproc>
    80004d30:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d32:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d36:	6785                	lui	a5,0x1
    80004d38:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004d3a:	97ca                	add	a5,a5,s2
    80004d3c:	777d                	lui	a4,0xfffff
    80004d3e:	8ff9                	and	a5,a5,a4
    80004d40:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d44:	4691                	li	a3,4
    80004d46:	6609                	lui	a2,0x2
    80004d48:	963e                	add	a2,a2,a5
    80004d4a:	85be                	mv	a1,a5
    80004d4c:	855a                	mv	a0,s6
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	6c2080e7          	jalr	1730(ra) # 80001410 <uvmalloc>
    80004d56:	8c2a                	mv	s8,a0
  ip = 0;
    80004d58:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004d5a:	12050e63          	beqz	a0,80004e96 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d5e:	75f9                	lui	a1,0xffffe
    80004d60:	95aa                	add	a1,a1,a0
    80004d62:	855a                	mv	a0,s6
    80004d64:	ffffd097          	auipc	ra,0xffffd
    80004d68:	8d6080e7          	jalr	-1834(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004d6c:	7afd                	lui	s5,0xfffff
    80004d6e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d70:	df043783          	ld	a5,-528(s0)
    80004d74:	6388                	ld	a0,0(a5)
    80004d76:	c925                	beqz	a0,80004de6 <exec+0x224>
    80004d78:	e9040993          	addi	s3,s0,-368
    80004d7c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004d80:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d82:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	0ca080e7          	jalr	202(ra) # 80000e4e <strlen>
    80004d8c:	0015079b          	addiw	a5,a0,1
    80004d90:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004d94:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004d98:	13596663          	bltu	s2,s5,80004ec4 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004d9c:	df043d83          	ld	s11,-528(s0)
    80004da0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004da4:	8552                	mv	a0,s4
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	0a8080e7          	jalr	168(ra) # 80000e4e <strlen>
    80004dae:	0015069b          	addiw	a3,a0,1
    80004db2:	8652                	mv	a2,s4
    80004db4:	85ca                	mv	a1,s2
    80004db6:	855a                	mv	a0,s6
    80004db8:	ffffd097          	auipc	ra,0xffffd
    80004dbc:	8b4080e7          	jalr	-1868(ra) # 8000166c <copyout>
    80004dc0:	10054663          	bltz	a0,80004ecc <exec+0x30a>
    ustack[argc] = sp;
    80004dc4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004dc8:	0485                	addi	s1,s1,1
    80004dca:	008d8793          	addi	a5,s11,8
    80004dce:	def43823          	sd	a5,-528(s0)
    80004dd2:	008db503          	ld	a0,8(s11)
    80004dd6:	c911                	beqz	a0,80004dea <exec+0x228>
    if(argc >= MAXARG)
    80004dd8:	09a1                	addi	s3,s3,8
    80004dda:	fb3c95e3          	bne	s9,s3,80004d84 <exec+0x1c2>
  sz = sz1;
    80004dde:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004de2:	4a81                	li	s5,0
    80004de4:	a84d                	j	80004e96 <exec+0x2d4>
  sp = sz;
    80004de6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004de8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004dea:	00349793          	slli	a5,s1,0x3
    80004dee:	f9078793          	addi	a5,a5,-112
    80004df2:	97a2                	add	a5,a5,s0
    80004df4:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004df8:	00148693          	addi	a3,s1,1
    80004dfc:	068e                	slli	a3,a3,0x3
    80004dfe:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e02:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e06:	01597663          	bgeu	s2,s5,80004e12 <exec+0x250>
  sz = sz1;
    80004e0a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e0e:	4a81                	li	s5,0
    80004e10:	a059                	j	80004e96 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e12:	e9040613          	addi	a2,s0,-368
    80004e16:	85ca                	mv	a1,s2
    80004e18:	855a                	mv	a0,s6
    80004e1a:	ffffd097          	auipc	ra,0xffffd
    80004e1e:	852080e7          	jalr	-1966(ra) # 8000166c <copyout>
    80004e22:	0a054963          	bltz	a0,80004ed4 <exec+0x312>
  p->trapframe->a1 = sp;
    80004e26:	058bb783          	ld	a5,88(s7)
    80004e2a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e2e:	de843783          	ld	a5,-536(s0)
    80004e32:	0007c703          	lbu	a4,0(a5)
    80004e36:	cf11                	beqz	a4,80004e52 <exec+0x290>
    80004e38:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e3a:	02f00693          	li	a3,47
    80004e3e:	a039                	j	80004e4c <exec+0x28a>
      last = s+1;
    80004e40:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e44:	0785                	addi	a5,a5,1
    80004e46:	fff7c703          	lbu	a4,-1(a5)
    80004e4a:	c701                	beqz	a4,80004e52 <exec+0x290>
    if(*s == '/')
    80004e4c:	fed71ce3          	bne	a4,a3,80004e44 <exec+0x282>
    80004e50:	bfc5                	j	80004e40 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e52:	4641                	li	a2,16
    80004e54:	de843583          	ld	a1,-536(s0)
    80004e58:	158b8513          	addi	a0,s7,344
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	fc0080e7          	jalr	-64(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004e64:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e68:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e6c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e70:	058bb783          	ld	a5,88(s7)
    80004e74:	e6843703          	ld	a4,-408(s0)
    80004e78:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e7a:	058bb783          	ld	a5,88(s7)
    80004e7e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e82:	85ea                	mv	a1,s10
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	c88080e7          	jalr	-888(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004e8c:	0004851b          	sext.w	a0,s1
    80004e90:	b3f9                	j	80004c5e <exec+0x9c>
    80004e92:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004e96:	df843583          	ld	a1,-520(s0)
    80004e9a:	855a                	mv	a0,s6
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	c70080e7          	jalr	-912(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004ea4:	da0a93e3          	bnez	s5,80004c4a <exec+0x88>
  return -1;
    80004ea8:	557d                	li	a0,-1
    80004eaa:	bb55                	j	80004c5e <exec+0x9c>
    80004eac:	df243c23          	sd	s2,-520(s0)
    80004eb0:	b7dd                	j	80004e96 <exec+0x2d4>
    80004eb2:	df243c23          	sd	s2,-520(s0)
    80004eb6:	b7c5                	j	80004e96 <exec+0x2d4>
    80004eb8:	df243c23          	sd	s2,-520(s0)
    80004ebc:	bfe9                	j	80004e96 <exec+0x2d4>
    80004ebe:	df243c23          	sd	s2,-520(s0)
    80004ec2:	bfd1                	j	80004e96 <exec+0x2d4>
  sz = sz1;
    80004ec4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ec8:	4a81                	li	s5,0
    80004eca:	b7f1                	j	80004e96 <exec+0x2d4>
  sz = sz1;
    80004ecc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed0:	4a81                	li	s5,0
    80004ed2:	b7d1                	j	80004e96 <exec+0x2d4>
  sz = sz1;
    80004ed4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ed8:	4a81                	li	s5,0
    80004eda:	bf75                	j	80004e96 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004edc:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ee0:	e0843783          	ld	a5,-504(s0)
    80004ee4:	0017869b          	addiw	a3,a5,1
    80004ee8:	e0d43423          	sd	a3,-504(s0)
    80004eec:	e0043783          	ld	a5,-512(s0)
    80004ef0:	0387879b          	addiw	a5,a5,56
    80004ef4:	e8845703          	lhu	a4,-376(s0)
    80004ef8:	e0e6dfe3          	bge	a3,a4,80004d16 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004efc:	2781                	sext.w	a5,a5
    80004efe:	e0f43023          	sd	a5,-512(s0)
    80004f02:	03800713          	li	a4,56
    80004f06:	86be                	mv	a3,a5
    80004f08:	e1840613          	addi	a2,s0,-488
    80004f0c:	4581                	li	a1,0
    80004f0e:	8556                	mv	a0,s5
    80004f10:	fffff097          	auipc	ra,0xfffff
    80004f14:	a58080e7          	jalr	-1448(ra) # 80003968 <readi>
    80004f18:	03800793          	li	a5,56
    80004f1c:	f6f51be3          	bne	a0,a5,80004e92 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004f20:	e1842783          	lw	a5,-488(s0)
    80004f24:	4705                	li	a4,1
    80004f26:	fae79de3          	bne	a5,a4,80004ee0 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004f2a:	e4043483          	ld	s1,-448(s0)
    80004f2e:	e3843783          	ld	a5,-456(s0)
    80004f32:	f6f4ede3          	bltu	s1,a5,80004eac <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f36:	e2843783          	ld	a5,-472(s0)
    80004f3a:	94be                	add	s1,s1,a5
    80004f3c:	f6f4ebe3          	bltu	s1,a5,80004eb2 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80004f40:	de043703          	ld	a4,-544(s0)
    80004f44:	8ff9                	and	a5,a5,a4
    80004f46:	fbad                	bnez	a5,80004eb8 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004f48:	e1c42503          	lw	a0,-484(s0)
    80004f4c:	00000097          	auipc	ra,0x0
    80004f50:	c5c080e7          	jalr	-932(ra) # 80004ba8 <flags2perm>
    80004f54:	86aa                	mv	a3,a0
    80004f56:	8626                	mv	a2,s1
    80004f58:	85ca                	mv	a1,s2
    80004f5a:	855a                	mv	a0,s6
    80004f5c:	ffffc097          	auipc	ra,0xffffc
    80004f60:	4b4080e7          	jalr	1204(ra) # 80001410 <uvmalloc>
    80004f64:	dea43c23          	sd	a0,-520(s0)
    80004f68:	d939                	beqz	a0,80004ebe <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f6a:	e2843c03          	ld	s8,-472(s0)
    80004f6e:	e2042c83          	lw	s9,-480(s0)
    80004f72:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f76:	f60b83e3          	beqz	s7,80004edc <exec+0x31a>
    80004f7a:	89de                	mv	s3,s7
    80004f7c:	4481                	li	s1,0
    80004f7e:	bb9d                	j	80004cf4 <exec+0x132>

0000000080004f80 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f80:	7179                	addi	sp,sp,-48
    80004f82:	f406                	sd	ra,40(sp)
    80004f84:	f022                	sd	s0,32(sp)
    80004f86:	ec26                	sd	s1,24(sp)
    80004f88:	e84a                	sd	s2,16(sp)
    80004f8a:	1800                	addi	s0,sp,48
    80004f8c:	892e                	mv	s2,a1
    80004f8e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004f90:	fdc40593          	addi	a1,s0,-36
    80004f94:	ffffe097          	auipc	ra,0xffffe
    80004f98:	b9c080e7          	jalr	-1124(ra) # 80002b30 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004f9c:	fdc42703          	lw	a4,-36(s0)
    80004fa0:	47bd                	li	a5,15
    80004fa2:	02e7eb63          	bltu	a5,a4,80004fd8 <argfd+0x58>
    80004fa6:	ffffd097          	auipc	ra,0xffffd
    80004faa:	a06080e7          	jalr	-1530(ra) # 800019ac <myproc>
    80004fae:	fdc42703          	lw	a4,-36(s0)
    80004fb2:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd29a>
    80004fb6:	078e                	slli	a5,a5,0x3
    80004fb8:	953e                	add	a0,a0,a5
    80004fba:	611c                	ld	a5,0(a0)
    80004fbc:	c385                	beqz	a5,80004fdc <argfd+0x5c>
    return -1;
  if(pfd)
    80004fbe:	00090463          	beqz	s2,80004fc6 <argfd+0x46>
    *pfd = fd;
    80004fc2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fc6:	4501                	li	a0,0
  if(pf)
    80004fc8:	c091                	beqz	s1,80004fcc <argfd+0x4c>
    *pf = f;
    80004fca:	e09c                	sd	a5,0(s1)
}
    80004fcc:	70a2                	ld	ra,40(sp)
    80004fce:	7402                	ld	s0,32(sp)
    80004fd0:	64e2                	ld	s1,24(sp)
    80004fd2:	6942                	ld	s2,16(sp)
    80004fd4:	6145                	addi	sp,sp,48
    80004fd6:	8082                	ret
    return -1;
    80004fd8:	557d                	li	a0,-1
    80004fda:	bfcd                	j	80004fcc <argfd+0x4c>
    80004fdc:	557d                	li	a0,-1
    80004fde:	b7fd                	j	80004fcc <argfd+0x4c>

0000000080004fe0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fe0:	1101                	addi	sp,sp,-32
    80004fe2:	ec06                	sd	ra,24(sp)
    80004fe4:	e822                	sd	s0,16(sp)
    80004fe6:	e426                	sd	s1,8(sp)
    80004fe8:	1000                	addi	s0,sp,32
    80004fea:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	9c0080e7          	jalr	-1600(ra) # 800019ac <myproc>
    80004ff4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004ff6:	0d050793          	addi	a5,a0,208
    80004ffa:	4501                	li	a0,0
    80004ffc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004ffe:	6398                	ld	a4,0(a5)
    80005000:	cb19                	beqz	a4,80005016 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005002:	2505                	addiw	a0,a0,1
    80005004:	07a1                	addi	a5,a5,8
    80005006:	fed51ce3          	bne	a0,a3,80004ffe <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000500a:	557d                	li	a0,-1
}
    8000500c:	60e2                	ld	ra,24(sp)
    8000500e:	6442                	ld	s0,16(sp)
    80005010:	64a2                	ld	s1,8(sp)
    80005012:	6105                	addi	sp,sp,32
    80005014:	8082                	ret
      p->ofile[fd] = f;
    80005016:	01a50793          	addi	a5,a0,26
    8000501a:	078e                	slli	a5,a5,0x3
    8000501c:	963e                	add	a2,a2,a5
    8000501e:	e204                	sd	s1,0(a2)
      return fd;
    80005020:	b7f5                	j	8000500c <fdalloc+0x2c>

0000000080005022 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005022:	715d                	addi	sp,sp,-80
    80005024:	e486                	sd	ra,72(sp)
    80005026:	e0a2                	sd	s0,64(sp)
    80005028:	fc26                	sd	s1,56(sp)
    8000502a:	f84a                	sd	s2,48(sp)
    8000502c:	f44e                	sd	s3,40(sp)
    8000502e:	f052                	sd	s4,32(sp)
    80005030:	ec56                	sd	s5,24(sp)
    80005032:	e85a                	sd	s6,16(sp)
    80005034:	0880                	addi	s0,sp,80
    80005036:	8b2e                	mv	s6,a1
    80005038:	89b2                	mv	s3,a2
    8000503a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000503c:	fb040593          	addi	a1,s0,-80
    80005040:	fffff097          	auipc	ra,0xfffff
    80005044:	e3e080e7          	jalr	-450(ra) # 80003e7e <nameiparent>
    80005048:	84aa                	mv	s1,a0
    8000504a:	14050f63          	beqz	a0,800051a8 <create+0x186>
    return 0;

  ilock(dp);
    8000504e:	ffffe097          	auipc	ra,0xffffe
    80005052:	666080e7          	jalr	1638(ra) # 800036b4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005056:	4601                	li	a2,0
    80005058:	fb040593          	addi	a1,s0,-80
    8000505c:	8526                	mv	a0,s1
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	b3a080e7          	jalr	-1222(ra) # 80003b98 <dirlookup>
    80005066:	8aaa                	mv	s5,a0
    80005068:	c931                	beqz	a0,800050bc <create+0x9a>
    iunlockput(dp);
    8000506a:	8526                	mv	a0,s1
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	8aa080e7          	jalr	-1878(ra) # 80003916 <iunlockput>
    ilock(ip);
    80005074:	8556                	mv	a0,s5
    80005076:	ffffe097          	auipc	ra,0xffffe
    8000507a:	63e080e7          	jalr	1598(ra) # 800036b4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000507e:	000b059b          	sext.w	a1,s6
    80005082:	4789                	li	a5,2
    80005084:	02f59563          	bne	a1,a5,800050ae <create+0x8c>
    80005088:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd2c4>
    8000508c:	37f9                	addiw	a5,a5,-2
    8000508e:	17c2                	slli	a5,a5,0x30
    80005090:	93c1                	srli	a5,a5,0x30
    80005092:	4705                	li	a4,1
    80005094:	00f76d63          	bltu	a4,a5,800050ae <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005098:	8556                	mv	a0,s5
    8000509a:	60a6                	ld	ra,72(sp)
    8000509c:	6406                	ld	s0,64(sp)
    8000509e:	74e2                	ld	s1,56(sp)
    800050a0:	7942                	ld	s2,48(sp)
    800050a2:	79a2                	ld	s3,40(sp)
    800050a4:	7a02                	ld	s4,32(sp)
    800050a6:	6ae2                	ld	s5,24(sp)
    800050a8:	6b42                	ld	s6,16(sp)
    800050aa:	6161                	addi	sp,sp,80
    800050ac:	8082                	ret
    iunlockput(ip);
    800050ae:	8556                	mv	a0,s5
    800050b0:	fffff097          	auipc	ra,0xfffff
    800050b4:	866080e7          	jalr	-1946(ra) # 80003916 <iunlockput>
    return 0;
    800050b8:	4a81                	li	s5,0
    800050ba:	bff9                	j	80005098 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800050bc:	85da                	mv	a1,s6
    800050be:	4088                	lw	a0,0(s1)
    800050c0:	ffffe097          	auipc	ra,0xffffe
    800050c4:	456080e7          	jalr	1110(ra) # 80003516 <ialloc>
    800050c8:	8a2a                	mv	s4,a0
    800050ca:	c539                	beqz	a0,80005118 <create+0xf6>
  ilock(ip);
    800050cc:	ffffe097          	auipc	ra,0xffffe
    800050d0:	5e8080e7          	jalr	1512(ra) # 800036b4 <ilock>
  ip->major = major;
    800050d4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800050d8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800050dc:	4905                	li	s2,1
    800050de:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800050e2:	8552                	mv	a0,s4
    800050e4:	ffffe097          	auipc	ra,0xffffe
    800050e8:	504080e7          	jalr	1284(ra) # 800035e8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050ec:	000b059b          	sext.w	a1,s6
    800050f0:	03258b63          	beq	a1,s2,80005126 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800050f4:	004a2603          	lw	a2,4(s4)
    800050f8:	fb040593          	addi	a1,s0,-80
    800050fc:	8526                	mv	a0,s1
    800050fe:	fffff097          	auipc	ra,0xfffff
    80005102:	cb0080e7          	jalr	-848(ra) # 80003dae <dirlink>
    80005106:	06054f63          	bltz	a0,80005184 <create+0x162>
  iunlockput(dp);
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	80a080e7          	jalr	-2038(ra) # 80003916 <iunlockput>
  return ip;
    80005114:	8ad2                	mv	s5,s4
    80005116:	b749                	j	80005098 <create+0x76>
    iunlockput(dp);
    80005118:	8526                	mv	a0,s1
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	7fc080e7          	jalr	2044(ra) # 80003916 <iunlockput>
    return 0;
    80005122:	8ad2                	mv	s5,s4
    80005124:	bf95                	j	80005098 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005126:	004a2603          	lw	a2,4(s4)
    8000512a:	00003597          	auipc	a1,0x3
    8000512e:	5e658593          	addi	a1,a1,1510 # 80008710 <syscalls+0x2a8>
    80005132:	8552                	mv	a0,s4
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	c7a080e7          	jalr	-902(ra) # 80003dae <dirlink>
    8000513c:	04054463          	bltz	a0,80005184 <create+0x162>
    80005140:	40d0                	lw	a2,4(s1)
    80005142:	00003597          	auipc	a1,0x3
    80005146:	5d658593          	addi	a1,a1,1494 # 80008718 <syscalls+0x2b0>
    8000514a:	8552                	mv	a0,s4
    8000514c:	fffff097          	auipc	ra,0xfffff
    80005150:	c62080e7          	jalr	-926(ra) # 80003dae <dirlink>
    80005154:	02054863          	bltz	a0,80005184 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005158:	004a2603          	lw	a2,4(s4)
    8000515c:	fb040593          	addi	a1,s0,-80
    80005160:	8526                	mv	a0,s1
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	c4c080e7          	jalr	-948(ra) # 80003dae <dirlink>
    8000516a:	00054d63          	bltz	a0,80005184 <create+0x162>
    dp->nlink++;  // for ".."
    8000516e:	04a4d783          	lhu	a5,74(s1)
    80005172:	2785                	addiw	a5,a5,1
    80005174:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005178:	8526                	mv	a0,s1
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	46e080e7          	jalr	1134(ra) # 800035e8 <iupdate>
    80005182:	b761                	j	8000510a <create+0xe8>
  ip->nlink = 0;
    80005184:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005188:	8552                	mv	a0,s4
    8000518a:	ffffe097          	auipc	ra,0xffffe
    8000518e:	45e080e7          	jalr	1118(ra) # 800035e8 <iupdate>
  iunlockput(ip);
    80005192:	8552                	mv	a0,s4
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	782080e7          	jalr	1922(ra) # 80003916 <iunlockput>
  iunlockput(dp);
    8000519c:	8526                	mv	a0,s1
    8000519e:	ffffe097          	auipc	ra,0xffffe
    800051a2:	778080e7          	jalr	1912(ra) # 80003916 <iunlockput>
  return 0;
    800051a6:	bdcd                	j	80005098 <create+0x76>
    return 0;
    800051a8:	8aaa                	mv	s5,a0
    800051aa:	b5fd                	j	80005098 <create+0x76>

00000000800051ac <sys_dup>:
{
    800051ac:	7179                	addi	sp,sp,-48
    800051ae:	f406                	sd	ra,40(sp)
    800051b0:	f022                	sd	s0,32(sp)
    800051b2:	ec26                	sd	s1,24(sp)
    800051b4:	e84a                	sd	s2,16(sp)
    800051b6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800051b8:	fd840613          	addi	a2,s0,-40
    800051bc:	4581                	li	a1,0
    800051be:	4501                	li	a0,0
    800051c0:	00000097          	auipc	ra,0x0
    800051c4:	dc0080e7          	jalr	-576(ra) # 80004f80 <argfd>
    return -1;
    800051c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051ca:	02054363          	bltz	a0,800051f0 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800051ce:	fd843903          	ld	s2,-40(s0)
    800051d2:	854a                	mv	a0,s2
    800051d4:	00000097          	auipc	ra,0x0
    800051d8:	e0c080e7          	jalr	-500(ra) # 80004fe0 <fdalloc>
    800051dc:	84aa                	mv	s1,a0
    return -1;
    800051de:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051e0:	00054863          	bltz	a0,800051f0 <sys_dup+0x44>
  filedup(f);
    800051e4:	854a                	mv	a0,s2
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	310080e7          	jalr	784(ra) # 800044f6 <filedup>
  return fd;
    800051ee:	87a6                	mv	a5,s1
}
    800051f0:	853e                	mv	a0,a5
    800051f2:	70a2                	ld	ra,40(sp)
    800051f4:	7402                	ld	s0,32(sp)
    800051f6:	64e2                	ld	s1,24(sp)
    800051f8:	6942                	ld	s2,16(sp)
    800051fa:	6145                	addi	sp,sp,48
    800051fc:	8082                	ret

00000000800051fe <sys_read>:
{
    800051fe:	7179                	addi	sp,sp,-48
    80005200:	f406                	sd	ra,40(sp)
    80005202:	f022                	sd	s0,32(sp)
    80005204:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005206:	fd840593          	addi	a1,s0,-40
    8000520a:	4505                	li	a0,1
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	944080e7          	jalr	-1724(ra) # 80002b50 <argaddr>
  argint(2, &n);
    80005214:	fe440593          	addi	a1,s0,-28
    80005218:	4509                	li	a0,2
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	916080e7          	jalr	-1770(ra) # 80002b30 <argint>
  if(argfd(0, 0, &f) < 0)
    80005222:	fe840613          	addi	a2,s0,-24
    80005226:	4581                	li	a1,0
    80005228:	4501                	li	a0,0
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	d56080e7          	jalr	-682(ra) # 80004f80 <argfd>
    80005232:	87aa                	mv	a5,a0
    return -1;
    80005234:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005236:	0007cc63          	bltz	a5,8000524e <sys_read+0x50>
  return fileread(f, p, n);
    8000523a:	fe442603          	lw	a2,-28(s0)
    8000523e:	fd843583          	ld	a1,-40(s0)
    80005242:	fe843503          	ld	a0,-24(s0)
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	43c080e7          	jalr	1084(ra) # 80004682 <fileread>
}
    8000524e:	70a2                	ld	ra,40(sp)
    80005250:	7402                	ld	s0,32(sp)
    80005252:	6145                	addi	sp,sp,48
    80005254:	8082                	ret

0000000080005256 <sys_write>:
{
    80005256:	7179                	addi	sp,sp,-48
    80005258:	f406                	sd	ra,40(sp)
    8000525a:	f022                	sd	s0,32(sp)
    8000525c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000525e:	fd840593          	addi	a1,s0,-40
    80005262:	4505                	li	a0,1
    80005264:	ffffe097          	auipc	ra,0xffffe
    80005268:	8ec080e7          	jalr	-1812(ra) # 80002b50 <argaddr>
  argint(2, &n);
    8000526c:	fe440593          	addi	a1,s0,-28
    80005270:	4509                	li	a0,2
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	8be080e7          	jalr	-1858(ra) # 80002b30 <argint>
  if(argfd(0, 0, &f) < 0)
    8000527a:	fe840613          	addi	a2,s0,-24
    8000527e:	4581                	li	a1,0
    80005280:	4501                	li	a0,0
    80005282:	00000097          	auipc	ra,0x0
    80005286:	cfe080e7          	jalr	-770(ra) # 80004f80 <argfd>
    8000528a:	87aa                	mv	a5,a0
    return -1;
    8000528c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000528e:	0007cc63          	bltz	a5,800052a6 <sys_write+0x50>
  return filewrite(f, p, n);
    80005292:	fe442603          	lw	a2,-28(s0)
    80005296:	fd843583          	ld	a1,-40(s0)
    8000529a:	fe843503          	ld	a0,-24(s0)
    8000529e:	fffff097          	auipc	ra,0xfffff
    800052a2:	4a6080e7          	jalr	1190(ra) # 80004744 <filewrite>
}
    800052a6:	70a2                	ld	ra,40(sp)
    800052a8:	7402                	ld	s0,32(sp)
    800052aa:	6145                	addi	sp,sp,48
    800052ac:	8082                	ret

00000000800052ae <sys_close>:
{
    800052ae:	1101                	addi	sp,sp,-32
    800052b0:	ec06                	sd	ra,24(sp)
    800052b2:	e822                	sd	s0,16(sp)
    800052b4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052b6:	fe040613          	addi	a2,s0,-32
    800052ba:	fec40593          	addi	a1,s0,-20
    800052be:	4501                	li	a0,0
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	cc0080e7          	jalr	-832(ra) # 80004f80 <argfd>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052ca:	02054463          	bltz	a0,800052f2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052ce:	ffffc097          	auipc	ra,0xffffc
    800052d2:	6de080e7          	jalr	1758(ra) # 800019ac <myproc>
    800052d6:	fec42783          	lw	a5,-20(s0)
    800052da:	07e9                	addi	a5,a5,26
    800052dc:	078e                	slli	a5,a5,0x3
    800052de:	953e                	add	a0,a0,a5
    800052e0:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800052e4:	fe043503          	ld	a0,-32(s0)
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	260080e7          	jalr	608(ra) # 80004548 <fileclose>
  return 0;
    800052f0:	4781                	li	a5,0
}
    800052f2:	853e                	mv	a0,a5
    800052f4:	60e2                	ld	ra,24(sp)
    800052f6:	6442                	ld	s0,16(sp)
    800052f8:	6105                	addi	sp,sp,32
    800052fa:	8082                	ret

00000000800052fc <sys_fstat>:
{
    800052fc:	1101                	addi	sp,sp,-32
    800052fe:	ec06                	sd	ra,24(sp)
    80005300:	e822                	sd	s0,16(sp)
    80005302:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005304:	fe040593          	addi	a1,s0,-32
    80005308:	4505                	li	a0,1
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	846080e7          	jalr	-1978(ra) # 80002b50 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005312:	fe840613          	addi	a2,s0,-24
    80005316:	4581                	li	a1,0
    80005318:	4501                	li	a0,0
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	c66080e7          	jalr	-922(ra) # 80004f80 <argfd>
    80005322:	87aa                	mv	a5,a0
    return -1;
    80005324:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005326:	0007ca63          	bltz	a5,8000533a <sys_fstat+0x3e>
  return filestat(f, st);
    8000532a:	fe043583          	ld	a1,-32(s0)
    8000532e:	fe843503          	ld	a0,-24(s0)
    80005332:	fffff097          	auipc	ra,0xfffff
    80005336:	2de080e7          	jalr	734(ra) # 80004610 <filestat>
}
    8000533a:	60e2                	ld	ra,24(sp)
    8000533c:	6442                	ld	s0,16(sp)
    8000533e:	6105                	addi	sp,sp,32
    80005340:	8082                	ret

0000000080005342 <sys_link>:
{
    80005342:	7169                	addi	sp,sp,-304
    80005344:	f606                	sd	ra,296(sp)
    80005346:	f222                	sd	s0,288(sp)
    80005348:	ee26                	sd	s1,280(sp)
    8000534a:	ea4a                	sd	s2,272(sp)
    8000534c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000534e:	08000613          	li	a2,128
    80005352:	ed040593          	addi	a1,s0,-304
    80005356:	4501                	li	a0,0
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	818080e7          	jalr	-2024(ra) # 80002b70 <argstr>
    return -1;
    80005360:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005362:	10054e63          	bltz	a0,8000547e <sys_link+0x13c>
    80005366:	08000613          	li	a2,128
    8000536a:	f5040593          	addi	a1,s0,-176
    8000536e:	4505                	li	a0,1
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	800080e7          	jalr	-2048(ra) # 80002b70 <argstr>
    return -1;
    80005378:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000537a:	10054263          	bltz	a0,8000547e <sys_link+0x13c>
  begin_op();
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	d02080e7          	jalr	-766(ra) # 80004080 <begin_op>
  if((ip = namei(old)) == 0){
    80005386:	ed040513          	addi	a0,s0,-304
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	ad6080e7          	jalr	-1322(ra) # 80003e60 <namei>
    80005392:	84aa                	mv	s1,a0
    80005394:	c551                	beqz	a0,80005420 <sys_link+0xde>
  ilock(ip);
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	31e080e7          	jalr	798(ra) # 800036b4 <ilock>
  if(ip->type == T_DIR){
    8000539e:	04449703          	lh	a4,68(s1)
    800053a2:	4785                	li	a5,1
    800053a4:	08f70463          	beq	a4,a5,8000542c <sys_link+0xea>
  ip->nlink++;
    800053a8:	04a4d783          	lhu	a5,74(s1)
    800053ac:	2785                	addiw	a5,a5,1
    800053ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	234080e7          	jalr	564(ra) # 800035e8 <iupdate>
  iunlock(ip);
    800053bc:	8526                	mv	a0,s1
    800053be:	ffffe097          	auipc	ra,0xffffe
    800053c2:	3b8080e7          	jalr	952(ra) # 80003776 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053c6:	fd040593          	addi	a1,s0,-48
    800053ca:	f5040513          	addi	a0,s0,-176
    800053ce:	fffff097          	auipc	ra,0xfffff
    800053d2:	ab0080e7          	jalr	-1360(ra) # 80003e7e <nameiparent>
    800053d6:	892a                	mv	s2,a0
    800053d8:	c935                	beqz	a0,8000544c <sys_link+0x10a>
  ilock(dp);
    800053da:	ffffe097          	auipc	ra,0xffffe
    800053de:	2da080e7          	jalr	730(ra) # 800036b4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053e2:	00092703          	lw	a4,0(s2)
    800053e6:	409c                	lw	a5,0(s1)
    800053e8:	04f71d63          	bne	a4,a5,80005442 <sys_link+0x100>
    800053ec:	40d0                	lw	a2,4(s1)
    800053ee:	fd040593          	addi	a1,s0,-48
    800053f2:	854a                	mv	a0,s2
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	9ba080e7          	jalr	-1606(ra) # 80003dae <dirlink>
    800053fc:	04054363          	bltz	a0,80005442 <sys_link+0x100>
  iunlockput(dp);
    80005400:	854a                	mv	a0,s2
    80005402:	ffffe097          	auipc	ra,0xffffe
    80005406:	514080e7          	jalr	1300(ra) # 80003916 <iunlockput>
  iput(ip);
    8000540a:	8526                	mv	a0,s1
    8000540c:	ffffe097          	auipc	ra,0xffffe
    80005410:	462080e7          	jalr	1122(ra) # 8000386e <iput>
  end_op();
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	cea080e7          	jalr	-790(ra) # 800040fe <end_op>
  return 0;
    8000541c:	4781                	li	a5,0
    8000541e:	a085                	j	8000547e <sys_link+0x13c>
    end_op();
    80005420:	fffff097          	auipc	ra,0xfffff
    80005424:	cde080e7          	jalr	-802(ra) # 800040fe <end_op>
    return -1;
    80005428:	57fd                	li	a5,-1
    8000542a:	a891                	j	8000547e <sys_link+0x13c>
    iunlockput(ip);
    8000542c:	8526                	mv	a0,s1
    8000542e:	ffffe097          	auipc	ra,0xffffe
    80005432:	4e8080e7          	jalr	1256(ra) # 80003916 <iunlockput>
    end_op();
    80005436:	fffff097          	auipc	ra,0xfffff
    8000543a:	cc8080e7          	jalr	-824(ra) # 800040fe <end_op>
    return -1;
    8000543e:	57fd                	li	a5,-1
    80005440:	a83d                	j	8000547e <sys_link+0x13c>
    iunlockput(dp);
    80005442:	854a                	mv	a0,s2
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	4d2080e7          	jalr	1234(ra) # 80003916 <iunlockput>
  ilock(ip);
    8000544c:	8526                	mv	a0,s1
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	266080e7          	jalr	614(ra) # 800036b4 <ilock>
  ip->nlink--;
    80005456:	04a4d783          	lhu	a5,74(s1)
    8000545a:	37fd                	addiw	a5,a5,-1
    8000545c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005460:	8526                	mv	a0,s1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	186080e7          	jalr	390(ra) # 800035e8 <iupdate>
  iunlockput(ip);
    8000546a:	8526                	mv	a0,s1
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	4aa080e7          	jalr	1194(ra) # 80003916 <iunlockput>
  end_op();
    80005474:	fffff097          	auipc	ra,0xfffff
    80005478:	c8a080e7          	jalr	-886(ra) # 800040fe <end_op>
  return -1;
    8000547c:	57fd                	li	a5,-1
}
    8000547e:	853e                	mv	a0,a5
    80005480:	70b2                	ld	ra,296(sp)
    80005482:	7412                	ld	s0,288(sp)
    80005484:	64f2                	ld	s1,280(sp)
    80005486:	6952                	ld	s2,272(sp)
    80005488:	6155                	addi	sp,sp,304
    8000548a:	8082                	ret

000000008000548c <sys_unlink>:
{
    8000548c:	7151                	addi	sp,sp,-240
    8000548e:	f586                	sd	ra,232(sp)
    80005490:	f1a2                	sd	s0,224(sp)
    80005492:	eda6                	sd	s1,216(sp)
    80005494:	e9ca                	sd	s2,208(sp)
    80005496:	e5ce                	sd	s3,200(sp)
    80005498:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000549a:	08000613          	li	a2,128
    8000549e:	f3040593          	addi	a1,s0,-208
    800054a2:	4501                	li	a0,0
    800054a4:	ffffd097          	auipc	ra,0xffffd
    800054a8:	6cc080e7          	jalr	1740(ra) # 80002b70 <argstr>
    800054ac:	18054163          	bltz	a0,8000562e <sys_unlink+0x1a2>
  begin_op();
    800054b0:	fffff097          	auipc	ra,0xfffff
    800054b4:	bd0080e7          	jalr	-1072(ra) # 80004080 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054b8:	fb040593          	addi	a1,s0,-80
    800054bc:	f3040513          	addi	a0,s0,-208
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	9be080e7          	jalr	-1602(ra) # 80003e7e <nameiparent>
    800054c8:	84aa                	mv	s1,a0
    800054ca:	c979                	beqz	a0,800055a0 <sys_unlink+0x114>
  ilock(dp);
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	1e8080e7          	jalr	488(ra) # 800036b4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054d4:	00003597          	auipc	a1,0x3
    800054d8:	23c58593          	addi	a1,a1,572 # 80008710 <syscalls+0x2a8>
    800054dc:	fb040513          	addi	a0,s0,-80
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	69e080e7          	jalr	1694(ra) # 80003b7e <namecmp>
    800054e8:	14050a63          	beqz	a0,8000563c <sys_unlink+0x1b0>
    800054ec:	00003597          	auipc	a1,0x3
    800054f0:	22c58593          	addi	a1,a1,556 # 80008718 <syscalls+0x2b0>
    800054f4:	fb040513          	addi	a0,s0,-80
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	686080e7          	jalr	1670(ra) # 80003b7e <namecmp>
    80005500:	12050e63          	beqz	a0,8000563c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005504:	f2c40613          	addi	a2,s0,-212
    80005508:	fb040593          	addi	a1,s0,-80
    8000550c:	8526                	mv	a0,s1
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	68a080e7          	jalr	1674(ra) # 80003b98 <dirlookup>
    80005516:	892a                	mv	s2,a0
    80005518:	12050263          	beqz	a0,8000563c <sys_unlink+0x1b0>
  ilock(ip);
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	198080e7          	jalr	408(ra) # 800036b4 <ilock>
  if(ip->nlink < 1)
    80005524:	04a91783          	lh	a5,74(s2)
    80005528:	08f05263          	blez	a5,800055ac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000552c:	04491703          	lh	a4,68(s2)
    80005530:	4785                	li	a5,1
    80005532:	08f70563          	beq	a4,a5,800055bc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005536:	4641                	li	a2,16
    80005538:	4581                	li	a1,0
    8000553a:	fc040513          	addi	a0,s0,-64
    8000553e:	ffffb097          	auipc	ra,0xffffb
    80005542:	794080e7          	jalr	1940(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005546:	4741                	li	a4,16
    80005548:	f2c42683          	lw	a3,-212(s0)
    8000554c:	fc040613          	addi	a2,s0,-64
    80005550:	4581                	li	a1,0
    80005552:	8526                	mv	a0,s1
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	50c080e7          	jalr	1292(ra) # 80003a60 <writei>
    8000555c:	47c1                	li	a5,16
    8000555e:	0af51563          	bne	a0,a5,80005608 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005562:	04491703          	lh	a4,68(s2)
    80005566:	4785                	li	a5,1
    80005568:	0af70863          	beq	a4,a5,80005618 <sys_unlink+0x18c>
  iunlockput(dp);
    8000556c:	8526                	mv	a0,s1
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	3a8080e7          	jalr	936(ra) # 80003916 <iunlockput>
  ip->nlink--;
    80005576:	04a95783          	lhu	a5,74(s2)
    8000557a:	37fd                	addiw	a5,a5,-1
    8000557c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005580:	854a                	mv	a0,s2
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	066080e7          	jalr	102(ra) # 800035e8 <iupdate>
  iunlockput(ip);
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	38a080e7          	jalr	906(ra) # 80003916 <iunlockput>
  end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	b6a080e7          	jalr	-1174(ra) # 800040fe <end_op>
  return 0;
    8000559c:	4501                	li	a0,0
    8000559e:	a84d                	j	80005650 <sys_unlink+0x1c4>
    end_op();
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	b5e080e7          	jalr	-1186(ra) # 800040fe <end_op>
    return -1;
    800055a8:	557d                	li	a0,-1
    800055aa:	a05d                	j	80005650 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055ac:	00003517          	auipc	a0,0x3
    800055b0:	17450513          	addi	a0,a0,372 # 80008720 <syscalls+0x2b8>
    800055b4:	ffffb097          	auipc	ra,0xffffb
    800055b8:	f8c080e7          	jalr	-116(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055bc:	04c92703          	lw	a4,76(s2)
    800055c0:	02000793          	li	a5,32
    800055c4:	f6e7f9e3          	bgeu	a5,a4,80005536 <sys_unlink+0xaa>
    800055c8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055cc:	4741                	li	a4,16
    800055ce:	86ce                	mv	a3,s3
    800055d0:	f1840613          	addi	a2,s0,-232
    800055d4:	4581                	li	a1,0
    800055d6:	854a                	mv	a0,s2
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	390080e7          	jalr	912(ra) # 80003968 <readi>
    800055e0:	47c1                	li	a5,16
    800055e2:	00f51b63          	bne	a0,a5,800055f8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055e6:	f1845783          	lhu	a5,-232(s0)
    800055ea:	e7a1                	bnez	a5,80005632 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055ec:	29c1                	addiw	s3,s3,16
    800055ee:	04c92783          	lw	a5,76(s2)
    800055f2:	fcf9ede3          	bltu	s3,a5,800055cc <sys_unlink+0x140>
    800055f6:	b781                	j	80005536 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800055f8:	00003517          	auipc	a0,0x3
    800055fc:	14050513          	addi	a0,a0,320 # 80008738 <syscalls+0x2d0>
    80005600:	ffffb097          	auipc	ra,0xffffb
    80005604:	f40080e7          	jalr	-192(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005608:	00003517          	auipc	a0,0x3
    8000560c:	14850513          	addi	a0,a0,328 # 80008750 <syscalls+0x2e8>
    80005610:	ffffb097          	auipc	ra,0xffffb
    80005614:	f30080e7          	jalr	-208(ra) # 80000540 <panic>
    dp->nlink--;
    80005618:	04a4d783          	lhu	a5,74(s1)
    8000561c:	37fd                	addiw	a5,a5,-1
    8000561e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	fc4080e7          	jalr	-60(ra) # 800035e8 <iupdate>
    8000562c:	b781                	j	8000556c <sys_unlink+0xe0>
    return -1;
    8000562e:	557d                	li	a0,-1
    80005630:	a005                	j	80005650 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005632:	854a                	mv	a0,s2
    80005634:	ffffe097          	auipc	ra,0xffffe
    80005638:	2e2080e7          	jalr	738(ra) # 80003916 <iunlockput>
  iunlockput(dp);
    8000563c:	8526                	mv	a0,s1
    8000563e:	ffffe097          	auipc	ra,0xffffe
    80005642:	2d8080e7          	jalr	728(ra) # 80003916 <iunlockput>
  end_op();
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	ab8080e7          	jalr	-1352(ra) # 800040fe <end_op>
  return -1;
    8000564e:	557d                	li	a0,-1
}
    80005650:	70ae                	ld	ra,232(sp)
    80005652:	740e                	ld	s0,224(sp)
    80005654:	64ee                	ld	s1,216(sp)
    80005656:	694e                	ld	s2,208(sp)
    80005658:	69ae                	ld	s3,200(sp)
    8000565a:	616d                	addi	sp,sp,240
    8000565c:	8082                	ret

000000008000565e <sys_open>:

uint64
sys_open(void)
{
    8000565e:	7131                	addi	sp,sp,-192
    80005660:	fd06                	sd	ra,184(sp)
    80005662:	f922                	sd	s0,176(sp)
    80005664:	f526                	sd	s1,168(sp)
    80005666:	f14a                	sd	s2,160(sp)
    80005668:	ed4e                	sd	s3,152(sp)
    8000566a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000566c:	f4c40593          	addi	a1,s0,-180
    80005670:	4505                	li	a0,1
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	4be080e7          	jalr	1214(ra) # 80002b30 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000567a:	08000613          	li	a2,128
    8000567e:	f5040593          	addi	a1,s0,-176
    80005682:	4501                	li	a0,0
    80005684:	ffffd097          	auipc	ra,0xffffd
    80005688:	4ec080e7          	jalr	1260(ra) # 80002b70 <argstr>
    8000568c:	87aa                	mv	a5,a0
    return -1;
    8000568e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005690:	0a07c963          	bltz	a5,80005742 <sys_open+0xe4>

  begin_op();
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	9ec080e7          	jalr	-1556(ra) # 80004080 <begin_op>

  if(omode & O_CREATE){
    8000569c:	f4c42783          	lw	a5,-180(s0)
    800056a0:	2007f793          	andi	a5,a5,512
    800056a4:	cfc5                	beqz	a5,8000575c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056a6:	4681                	li	a3,0
    800056a8:	4601                	li	a2,0
    800056aa:	4589                	li	a1,2
    800056ac:	f5040513          	addi	a0,s0,-176
    800056b0:	00000097          	auipc	ra,0x0
    800056b4:	972080e7          	jalr	-1678(ra) # 80005022 <create>
    800056b8:	84aa                	mv	s1,a0
    if(ip == 0){
    800056ba:	c959                	beqz	a0,80005750 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056bc:	04449703          	lh	a4,68(s1)
    800056c0:	478d                	li	a5,3
    800056c2:	00f71763          	bne	a4,a5,800056d0 <sys_open+0x72>
    800056c6:	0464d703          	lhu	a4,70(s1)
    800056ca:	47a5                	li	a5,9
    800056cc:	0ce7ed63          	bltu	a5,a4,800057a6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	dbc080e7          	jalr	-580(ra) # 8000448c <filealloc>
    800056d8:	89aa                	mv	s3,a0
    800056da:	10050363          	beqz	a0,800057e0 <sys_open+0x182>
    800056de:	00000097          	auipc	ra,0x0
    800056e2:	902080e7          	jalr	-1790(ra) # 80004fe0 <fdalloc>
    800056e6:	892a                	mv	s2,a0
    800056e8:	0e054763          	bltz	a0,800057d6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056ec:	04449703          	lh	a4,68(s1)
    800056f0:	478d                	li	a5,3
    800056f2:	0cf70563          	beq	a4,a5,800057bc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800056f6:	4789                	li	a5,2
    800056f8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800056fc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005700:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005704:	f4c42783          	lw	a5,-180(s0)
    80005708:	0017c713          	xori	a4,a5,1
    8000570c:	8b05                	andi	a4,a4,1
    8000570e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005712:	0037f713          	andi	a4,a5,3
    80005716:	00e03733          	snez	a4,a4
    8000571a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000571e:	4007f793          	andi	a5,a5,1024
    80005722:	c791                	beqz	a5,8000572e <sys_open+0xd0>
    80005724:	04449703          	lh	a4,68(s1)
    80005728:	4789                	li	a5,2
    8000572a:	0af70063          	beq	a4,a5,800057ca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000572e:	8526                	mv	a0,s1
    80005730:	ffffe097          	auipc	ra,0xffffe
    80005734:	046080e7          	jalr	70(ra) # 80003776 <iunlock>
  end_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	9c6080e7          	jalr	-1594(ra) # 800040fe <end_op>

  return fd;
    80005740:	854a                	mv	a0,s2
}
    80005742:	70ea                	ld	ra,184(sp)
    80005744:	744a                	ld	s0,176(sp)
    80005746:	74aa                	ld	s1,168(sp)
    80005748:	790a                	ld	s2,160(sp)
    8000574a:	69ea                	ld	s3,152(sp)
    8000574c:	6129                	addi	sp,sp,192
    8000574e:	8082                	ret
      end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	9ae080e7          	jalr	-1618(ra) # 800040fe <end_op>
      return -1;
    80005758:	557d                	li	a0,-1
    8000575a:	b7e5                	j	80005742 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000575c:	f5040513          	addi	a0,s0,-176
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	700080e7          	jalr	1792(ra) # 80003e60 <namei>
    80005768:	84aa                	mv	s1,a0
    8000576a:	c905                	beqz	a0,8000579a <sys_open+0x13c>
    ilock(ip);
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	f48080e7          	jalr	-184(ra) # 800036b4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005774:	04449703          	lh	a4,68(s1)
    80005778:	4785                	li	a5,1
    8000577a:	f4f711e3          	bne	a4,a5,800056bc <sys_open+0x5e>
    8000577e:	f4c42783          	lw	a5,-180(s0)
    80005782:	d7b9                	beqz	a5,800056d0 <sys_open+0x72>
      iunlockput(ip);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	190080e7          	jalr	400(ra) # 80003916 <iunlockput>
      end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	970080e7          	jalr	-1680(ra) # 800040fe <end_op>
      return -1;
    80005796:	557d                	li	a0,-1
    80005798:	b76d                	j	80005742 <sys_open+0xe4>
      end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	964080e7          	jalr	-1692(ra) # 800040fe <end_op>
      return -1;
    800057a2:	557d                	li	a0,-1
    800057a4:	bf79                	j	80005742 <sys_open+0xe4>
    iunlockput(ip);
    800057a6:	8526                	mv	a0,s1
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	16e080e7          	jalr	366(ra) # 80003916 <iunlockput>
    end_op();
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	94e080e7          	jalr	-1714(ra) # 800040fe <end_op>
    return -1;
    800057b8:	557d                	li	a0,-1
    800057ba:	b761                	j	80005742 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057bc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057c0:	04649783          	lh	a5,70(s1)
    800057c4:	02f99223          	sh	a5,36(s3)
    800057c8:	bf25                	j	80005700 <sys_open+0xa2>
    itrunc(ip);
    800057ca:	8526                	mv	a0,s1
    800057cc:	ffffe097          	auipc	ra,0xffffe
    800057d0:	ff6080e7          	jalr	-10(ra) # 800037c2 <itrunc>
    800057d4:	bfa9                	j	8000572e <sys_open+0xd0>
      fileclose(f);
    800057d6:	854e                	mv	a0,s3
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	d70080e7          	jalr	-656(ra) # 80004548 <fileclose>
    iunlockput(ip);
    800057e0:	8526                	mv	a0,s1
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	134080e7          	jalr	308(ra) # 80003916 <iunlockput>
    end_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	914080e7          	jalr	-1772(ra) # 800040fe <end_op>
    return -1;
    800057f2:	557d                	li	a0,-1
    800057f4:	b7b9                	j	80005742 <sys_open+0xe4>

00000000800057f6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057f6:	7175                	addi	sp,sp,-144
    800057f8:	e506                	sd	ra,136(sp)
    800057fa:	e122                	sd	s0,128(sp)
    800057fc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	882080e7          	jalr	-1918(ra) # 80004080 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005806:	08000613          	li	a2,128
    8000580a:	f7040593          	addi	a1,s0,-144
    8000580e:	4501                	li	a0,0
    80005810:	ffffd097          	auipc	ra,0xffffd
    80005814:	360080e7          	jalr	864(ra) # 80002b70 <argstr>
    80005818:	02054963          	bltz	a0,8000584a <sys_mkdir+0x54>
    8000581c:	4681                	li	a3,0
    8000581e:	4601                	li	a2,0
    80005820:	4585                	li	a1,1
    80005822:	f7040513          	addi	a0,s0,-144
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	7fc080e7          	jalr	2044(ra) # 80005022 <create>
    8000582e:	cd11                	beqz	a0,8000584a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	0e6080e7          	jalr	230(ra) # 80003916 <iunlockput>
  end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	8c6080e7          	jalr	-1850(ra) # 800040fe <end_op>
  return 0;
    80005840:	4501                	li	a0,0
}
    80005842:	60aa                	ld	ra,136(sp)
    80005844:	640a                	ld	s0,128(sp)
    80005846:	6149                	addi	sp,sp,144
    80005848:	8082                	ret
    end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	8b4080e7          	jalr	-1868(ra) # 800040fe <end_op>
    return -1;
    80005852:	557d                	li	a0,-1
    80005854:	b7fd                	j	80005842 <sys_mkdir+0x4c>

0000000080005856 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005856:	7135                	addi	sp,sp,-160
    80005858:	ed06                	sd	ra,152(sp)
    8000585a:	e922                	sd	s0,144(sp)
    8000585c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	822080e7          	jalr	-2014(ra) # 80004080 <begin_op>
  argint(1, &major);
    80005866:	f6c40593          	addi	a1,s0,-148
    8000586a:	4505                	li	a0,1
    8000586c:	ffffd097          	auipc	ra,0xffffd
    80005870:	2c4080e7          	jalr	708(ra) # 80002b30 <argint>
  argint(2, &minor);
    80005874:	f6840593          	addi	a1,s0,-152
    80005878:	4509                	li	a0,2
    8000587a:	ffffd097          	auipc	ra,0xffffd
    8000587e:	2b6080e7          	jalr	694(ra) # 80002b30 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005882:	08000613          	li	a2,128
    80005886:	f7040593          	addi	a1,s0,-144
    8000588a:	4501                	li	a0,0
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	2e4080e7          	jalr	740(ra) # 80002b70 <argstr>
    80005894:	02054b63          	bltz	a0,800058ca <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005898:	f6841683          	lh	a3,-152(s0)
    8000589c:	f6c41603          	lh	a2,-148(s0)
    800058a0:	458d                	li	a1,3
    800058a2:	f7040513          	addi	a0,s0,-144
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	77c080e7          	jalr	1916(ra) # 80005022 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058ae:	cd11                	beqz	a0,800058ca <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	066080e7          	jalr	102(ra) # 80003916 <iunlockput>
  end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	846080e7          	jalr	-1978(ra) # 800040fe <end_op>
  return 0;
    800058c0:	4501                	li	a0,0
}
    800058c2:	60ea                	ld	ra,152(sp)
    800058c4:	644a                	ld	s0,144(sp)
    800058c6:	610d                	addi	sp,sp,160
    800058c8:	8082                	ret
    end_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	834080e7          	jalr	-1996(ra) # 800040fe <end_op>
    return -1;
    800058d2:	557d                	li	a0,-1
    800058d4:	b7fd                	j	800058c2 <sys_mknod+0x6c>

00000000800058d6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058d6:	7135                	addi	sp,sp,-160
    800058d8:	ed06                	sd	ra,152(sp)
    800058da:	e922                	sd	s0,144(sp)
    800058dc:	e526                	sd	s1,136(sp)
    800058de:	e14a                	sd	s2,128(sp)
    800058e0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058e2:	ffffc097          	auipc	ra,0xffffc
    800058e6:	0ca080e7          	jalr	202(ra) # 800019ac <myproc>
    800058ea:	892a                	mv	s2,a0
  
  begin_op();
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	794080e7          	jalr	1940(ra) # 80004080 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800058f4:	08000613          	li	a2,128
    800058f8:	f6040593          	addi	a1,s0,-160
    800058fc:	4501                	li	a0,0
    800058fe:	ffffd097          	auipc	ra,0xffffd
    80005902:	272080e7          	jalr	626(ra) # 80002b70 <argstr>
    80005906:	04054b63          	bltz	a0,8000595c <sys_chdir+0x86>
    8000590a:	f6040513          	addi	a0,s0,-160
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	552080e7          	jalr	1362(ra) # 80003e60 <namei>
    80005916:	84aa                	mv	s1,a0
    80005918:	c131                	beqz	a0,8000595c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	d9a080e7          	jalr	-614(ra) # 800036b4 <ilock>
  if(ip->type != T_DIR){
    80005922:	04449703          	lh	a4,68(s1)
    80005926:	4785                	li	a5,1
    80005928:	04f71063          	bne	a4,a5,80005968 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000592c:	8526                	mv	a0,s1
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	e48080e7          	jalr	-440(ra) # 80003776 <iunlock>
  iput(p->cwd);
    80005936:	15093503          	ld	a0,336(s2)
    8000593a:	ffffe097          	auipc	ra,0xffffe
    8000593e:	f34080e7          	jalr	-204(ra) # 8000386e <iput>
  end_op();
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	7bc080e7          	jalr	1980(ra) # 800040fe <end_op>
  p->cwd = ip;
    8000594a:	14993823          	sd	s1,336(s2)
  return 0;
    8000594e:	4501                	li	a0,0
}
    80005950:	60ea                	ld	ra,152(sp)
    80005952:	644a                	ld	s0,144(sp)
    80005954:	64aa                	ld	s1,136(sp)
    80005956:	690a                	ld	s2,128(sp)
    80005958:	610d                	addi	sp,sp,160
    8000595a:	8082                	ret
    end_op();
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	7a2080e7          	jalr	1954(ra) # 800040fe <end_op>
    return -1;
    80005964:	557d                	li	a0,-1
    80005966:	b7ed                	j	80005950 <sys_chdir+0x7a>
    iunlockput(ip);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	fac080e7          	jalr	-84(ra) # 80003916 <iunlockput>
    end_op();
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	78c080e7          	jalr	1932(ra) # 800040fe <end_op>
    return -1;
    8000597a:	557d                	li	a0,-1
    8000597c:	bfd1                	j	80005950 <sys_chdir+0x7a>

000000008000597e <sys_exec>:

uint64
sys_exec(void)
{
    8000597e:	7145                	addi	sp,sp,-464
    80005980:	e786                	sd	ra,456(sp)
    80005982:	e3a2                	sd	s0,448(sp)
    80005984:	ff26                	sd	s1,440(sp)
    80005986:	fb4a                	sd	s2,432(sp)
    80005988:	f74e                	sd	s3,424(sp)
    8000598a:	f352                	sd	s4,416(sp)
    8000598c:	ef56                	sd	s5,408(sp)
    8000598e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005990:	e3840593          	addi	a1,s0,-456
    80005994:	4505                	li	a0,1
    80005996:	ffffd097          	auipc	ra,0xffffd
    8000599a:	1ba080e7          	jalr	442(ra) # 80002b50 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000599e:	08000613          	li	a2,128
    800059a2:	f4040593          	addi	a1,s0,-192
    800059a6:	4501                	li	a0,0
    800059a8:	ffffd097          	auipc	ra,0xffffd
    800059ac:	1c8080e7          	jalr	456(ra) # 80002b70 <argstr>
    800059b0:	87aa                	mv	a5,a0
    return -1;
    800059b2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800059b4:	0c07c363          	bltz	a5,80005a7a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    800059b8:	10000613          	li	a2,256
    800059bc:	4581                	li	a1,0
    800059be:	e4040513          	addi	a0,s0,-448
    800059c2:	ffffb097          	auipc	ra,0xffffb
    800059c6:	310080e7          	jalr	784(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059ca:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059ce:	89a6                	mv	s3,s1
    800059d0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059d2:	02000a13          	li	s4,32
    800059d6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059da:	00391513          	slli	a0,s2,0x3
    800059de:	e3040593          	addi	a1,s0,-464
    800059e2:	e3843783          	ld	a5,-456(s0)
    800059e6:	953e                	add	a0,a0,a5
    800059e8:	ffffd097          	auipc	ra,0xffffd
    800059ec:	0aa080e7          	jalr	170(ra) # 80002a92 <fetchaddr>
    800059f0:	02054a63          	bltz	a0,80005a24 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800059f4:	e3043783          	ld	a5,-464(s0)
    800059f8:	c3b9                	beqz	a5,80005a3e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800059fa:	ffffb097          	auipc	ra,0xffffb
    800059fe:	0ec080e7          	jalr	236(ra) # 80000ae6 <kalloc>
    80005a02:	85aa                	mv	a1,a0
    80005a04:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a08:	cd11                	beqz	a0,80005a24 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a0a:	6605                	lui	a2,0x1
    80005a0c:	e3043503          	ld	a0,-464(s0)
    80005a10:	ffffd097          	auipc	ra,0xffffd
    80005a14:	0d4080e7          	jalr	212(ra) # 80002ae4 <fetchstr>
    80005a18:	00054663          	bltz	a0,80005a24 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005a1c:	0905                	addi	s2,s2,1
    80005a1e:	09a1                	addi	s3,s3,8
    80005a20:	fb491be3          	bne	s2,s4,800059d6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a24:	f4040913          	addi	s2,s0,-192
    80005a28:	6088                	ld	a0,0(s1)
    80005a2a:	c539                	beqz	a0,80005a78 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a2c:	ffffb097          	auipc	ra,0xffffb
    80005a30:	fbc080e7          	jalr	-68(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a34:	04a1                	addi	s1,s1,8
    80005a36:	ff2499e3          	bne	s1,s2,80005a28 <sys_exec+0xaa>
  return -1;
    80005a3a:	557d                	li	a0,-1
    80005a3c:	a83d                	j	80005a7a <sys_exec+0xfc>
      argv[i] = 0;
    80005a3e:	0a8e                	slli	s5,s5,0x3
    80005a40:	fc0a8793          	addi	a5,s5,-64
    80005a44:	00878ab3          	add	s5,a5,s0
    80005a48:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005a4c:	e4040593          	addi	a1,s0,-448
    80005a50:	f4040513          	addi	a0,s0,-192
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	16e080e7          	jalr	366(ra) # 80004bc2 <exec>
    80005a5c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a5e:	f4040993          	addi	s3,s0,-192
    80005a62:	6088                	ld	a0,0(s1)
    80005a64:	c901                	beqz	a0,80005a74 <sys_exec+0xf6>
    kfree(argv[i]);
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	f82080e7          	jalr	-126(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a6e:	04a1                	addi	s1,s1,8
    80005a70:	ff3499e3          	bne	s1,s3,80005a62 <sys_exec+0xe4>
  return ret;
    80005a74:	854a                	mv	a0,s2
    80005a76:	a011                	j	80005a7a <sys_exec+0xfc>
  return -1;
    80005a78:	557d                	li	a0,-1
}
    80005a7a:	60be                	ld	ra,456(sp)
    80005a7c:	641e                	ld	s0,448(sp)
    80005a7e:	74fa                	ld	s1,440(sp)
    80005a80:	795a                	ld	s2,432(sp)
    80005a82:	79ba                	ld	s3,424(sp)
    80005a84:	7a1a                	ld	s4,416(sp)
    80005a86:	6afa                	ld	s5,408(sp)
    80005a88:	6179                	addi	sp,sp,464
    80005a8a:	8082                	ret

0000000080005a8c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a8c:	7139                	addi	sp,sp,-64
    80005a8e:	fc06                	sd	ra,56(sp)
    80005a90:	f822                	sd	s0,48(sp)
    80005a92:	f426                	sd	s1,40(sp)
    80005a94:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005a96:	ffffc097          	auipc	ra,0xffffc
    80005a9a:	f16080e7          	jalr	-234(ra) # 800019ac <myproc>
    80005a9e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005aa0:	fd840593          	addi	a1,s0,-40
    80005aa4:	4501                	li	a0,0
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	0aa080e7          	jalr	170(ra) # 80002b50 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005aae:	fc840593          	addi	a1,s0,-56
    80005ab2:	fd040513          	addi	a0,s0,-48
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	dc2080e7          	jalr	-574(ra) # 80004878 <pipealloc>
    return -1;
    80005abe:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ac0:	0c054463          	bltz	a0,80005b88 <sys_pipe+0xfc>
  fd0 = -1;
    80005ac4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ac8:	fd043503          	ld	a0,-48(s0)
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	514080e7          	jalr	1300(ra) # 80004fe0 <fdalloc>
    80005ad4:	fca42223          	sw	a0,-60(s0)
    80005ad8:	08054b63          	bltz	a0,80005b6e <sys_pipe+0xe2>
    80005adc:	fc843503          	ld	a0,-56(s0)
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	500080e7          	jalr	1280(ra) # 80004fe0 <fdalloc>
    80005ae8:	fca42023          	sw	a0,-64(s0)
    80005aec:	06054863          	bltz	a0,80005b5c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005af0:	4691                	li	a3,4
    80005af2:	fc440613          	addi	a2,s0,-60
    80005af6:	fd843583          	ld	a1,-40(s0)
    80005afa:	68a8                	ld	a0,80(s1)
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	b70080e7          	jalr	-1168(ra) # 8000166c <copyout>
    80005b04:	02054063          	bltz	a0,80005b24 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b08:	4691                	li	a3,4
    80005b0a:	fc040613          	addi	a2,s0,-64
    80005b0e:	fd843583          	ld	a1,-40(s0)
    80005b12:	0591                	addi	a1,a1,4
    80005b14:	68a8                	ld	a0,80(s1)
    80005b16:	ffffc097          	auipc	ra,0xffffc
    80005b1a:	b56080e7          	jalr	-1194(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b1e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b20:	06055463          	bgez	a0,80005b88 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005b24:	fc442783          	lw	a5,-60(s0)
    80005b28:	07e9                	addi	a5,a5,26
    80005b2a:	078e                	slli	a5,a5,0x3
    80005b2c:	97a6                	add	a5,a5,s1
    80005b2e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b32:	fc042783          	lw	a5,-64(s0)
    80005b36:	07e9                	addi	a5,a5,26
    80005b38:	078e                	slli	a5,a5,0x3
    80005b3a:	94be                	add	s1,s1,a5
    80005b3c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005b40:	fd043503          	ld	a0,-48(s0)
    80005b44:	fffff097          	auipc	ra,0xfffff
    80005b48:	a04080e7          	jalr	-1532(ra) # 80004548 <fileclose>
    fileclose(wf);
    80005b4c:	fc843503          	ld	a0,-56(s0)
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	9f8080e7          	jalr	-1544(ra) # 80004548 <fileclose>
    return -1;
    80005b58:	57fd                	li	a5,-1
    80005b5a:	a03d                	j	80005b88 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005b5c:	fc442783          	lw	a5,-60(s0)
    80005b60:	0007c763          	bltz	a5,80005b6e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005b64:	07e9                	addi	a5,a5,26
    80005b66:	078e                	slli	a5,a5,0x3
    80005b68:	97a6                	add	a5,a5,s1
    80005b6a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005b6e:	fd043503          	ld	a0,-48(s0)
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	9d6080e7          	jalr	-1578(ra) # 80004548 <fileclose>
    fileclose(wf);
    80005b7a:	fc843503          	ld	a0,-56(s0)
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	9ca080e7          	jalr	-1590(ra) # 80004548 <fileclose>
    return -1;
    80005b86:	57fd                	li	a5,-1
}
    80005b88:	853e                	mv	a0,a5
    80005b8a:	70e2                	ld	ra,56(sp)
    80005b8c:	7442                	ld	s0,48(sp)
    80005b8e:	74a2                	ld	s1,40(sp)
    80005b90:	6121                	addi	sp,sp,64
    80005b92:	8082                	ret
	...

0000000080005ba0 <kernelvec>:
    80005ba0:	7111                	addi	sp,sp,-256
    80005ba2:	e006                	sd	ra,0(sp)
    80005ba4:	e40a                	sd	sp,8(sp)
    80005ba6:	e80e                	sd	gp,16(sp)
    80005ba8:	ec12                	sd	tp,24(sp)
    80005baa:	f016                	sd	t0,32(sp)
    80005bac:	f41a                	sd	t1,40(sp)
    80005bae:	f81e                	sd	t2,48(sp)
    80005bb0:	fc22                	sd	s0,56(sp)
    80005bb2:	e0a6                	sd	s1,64(sp)
    80005bb4:	e4aa                	sd	a0,72(sp)
    80005bb6:	e8ae                	sd	a1,80(sp)
    80005bb8:	ecb2                	sd	a2,88(sp)
    80005bba:	f0b6                	sd	a3,96(sp)
    80005bbc:	f4ba                	sd	a4,104(sp)
    80005bbe:	f8be                	sd	a5,112(sp)
    80005bc0:	fcc2                	sd	a6,120(sp)
    80005bc2:	e146                	sd	a7,128(sp)
    80005bc4:	e54a                	sd	s2,136(sp)
    80005bc6:	e94e                	sd	s3,144(sp)
    80005bc8:	ed52                	sd	s4,152(sp)
    80005bca:	f156                	sd	s5,160(sp)
    80005bcc:	f55a                	sd	s6,168(sp)
    80005bce:	f95e                	sd	s7,176(sp)
    80005bd0:	fd62                	sd	s8,184(sp)
    80005bd2:	e1e6                	sd	s9,192(sp)
    80005bd4:	e5ea                	sd	s10,200(sp)
    80005bd6:	e9ee                	sd	s11,208(sp)
    80005bd8:	edf2                	sd	t3,216(sp)
    80005bda:	f1f6                	sd	t4,224(sp)
    80005bdc:	f5fa                	sd	t5,232(sp)
    80005bde:	f9fe                	sd	t6,240(sp)
    80005be0:	d7ffc0ef          	jal	ra,8000295e <kerneltrap>
    80005be4:	6082                	ld	ra,0(sp)
    80005be6:	6122                	ld	sp,8(sp)
    80005be8:	61c2                	ld	gp,16(sp)
    80005bea:	7282                	ld	t0,32(sp)
    80005bec:	7322                	ld	t1,40(sp)
    80005bee:	73c2                	ld	t2,48(sp)
    80005bf0:	7462                	ld	s0,56(sp)
    80005bf2:	6486                	ld	s1,64(sp)
    80005bf4:	6526                	ld	a0,72(sp)
    80005bf6:	65c6                	ld	a1,80(sp)
    80005bf8:	6666                	ld	a2,88(sp)
    80005bfa:	7686                	ld	a3,96(sp)
    80005bfc:	7726                	ld	a4,104(sp)
    80005bfe:	77c6                	ld	a5,112(sp)
    80005c00:	7866                	ld	a6,120(sp)
    80005c02:	688a                	ld	a7,128(sp)
    80005c04:	692a                	ld	s2,136(sp)
    80005c06:	69ca                	ld	s3,144(sp)
    80005c08:	6a6a                	ld	s4,152(sp)
    80005c0a:	7a8a                	ld	s5,160(sp)
    80005c0c:	7b2a                	ld	s6,168(sp)
    80005c0e:	7bca                	ld	s7,176(sp)
    80005c10:	7c6a                	ld	s8,184(sp)
    80005c12:	6c8e                	ld	s9,192(sp)
    80005c14:	6d2e                	ld	s10,200(sp)
    80005c16:	6dce                	ld	s11,208(sp)
    80005c18:	6e6e                	ld	t3,216(sp)
    80005c1a:	7e8e                	ld	t4,224(sp)
    80005c1c:	7f2e                	ld	t5,232(sp)
    80005c1e:	7fce                	ld	t6,240(sp)
    80005c20:	6111                	addi	sp,sp,256
    80005c22:	10200073          	sret
    80005c26:	00000013          	nop
    80005c2a:	00000013          	nop
    80005c2e:	0001                	nop

0000000080005c30 <timervec>:
    80005c30:	34051573          	csrrw	a0,mscratch,a0
    80005c34:	e10c                	sd	a1,0(a0)
    80005c36:	e510                	sd	a2,8(a0)
    80005c38:	e914                	sd	a3,16(a0)
    80005c3a:	6d0c                	ld	a1,24(a0)
    80005c3c:	7110                	ld	a2,32(a0)
    80005c3e:	6194                	ld	a3,0(a1)
    80005c40:	96b2                	add	a3,a3,a2
    80005c42:	e194                	sd	a3,0(a1)
    80005c44:	4589                	li	a1,2
    80005c46:	14459073          	csrw	sip,a1
    80005c4a:	6914                	ld	a3,16(a0)
    80005c4c:	6510                	ld	a2,8(a0)
    80005c4e:	610c                	ld	a1,0(a0)
    80005c50:	34051573          	csrrw	a0,mscratch,a0
    80005c54:	30200073          	mret
	...

0000000080005c5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c5a:	1141                	addi	sp,sp,-16
    80005c5c:	e422                	sd	s0,8(sp)
    80005c5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c60:	0c0007b7          	lui	a5,0xc000
    80005c64:	4705                	li	a4,1
    80005c66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c68:	c3d8                	sw	a4,4(a5)
}
    80005c6a:	6422                	ld	s0,8(sp)
    80005c6c:	0141                	addi	sp,sp,16
    80005c6e:	8082                	ret

0000000080005c70 <plicinithart>:

void
plicinithart(void)
{
    80005c70:	1141                	addi	sp,sp,-16
    80005c72:	e406                	sd	ra,8(sp)
    80005c74:	e022                	sd	s0,0(sp)
    80005c76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c78:	ffffc097          	auipc	ra,0xffffc
    80005c7c:	d08080e7          	jalr	-760(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c80:	0085171b          	slliw	a4,a0,0x8
    80005c84:	0c0027b7          	lui	a5,0xc002
    80005c88:	97ba                	add	a5,a5,a4
    80005c8a:	40200713          	li	a4,1026
    80005c8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005c92:	00d5151b          	slliw	a0,a0,0xd
    80005c96:	0c2017b7          	lui	a5,0xc201
    80005c9a:	97aa                	add	a5,a5,a0
    80005c9c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005ca0:	60a2                	ld	ra,8(sp)
    80005ca2:	6402                	ld	s0,0(sp)
    80005ca4:	0141                	addi	sp,sp,16
    80005ca6:	8082                	ret

0000000080005ca8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ca8:	1141                	addi	sp,sp,-16
    80005caa:	e406                	sd	ra,8(sp)
    80005cac:	e022                	sd	s0,0(sp)
    80005cae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cb0:	ffffc097          	auipc	ra,0xffffc
    80005cb4:	cd0080e7          	jalr	-816(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cb8:	00d5151b          	slliw	a0,a0,0xd
    80005cbc:	0c2017b7          	lui	a5,0xc201
    80005cc0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005cc2:	43c8                	lw	a0,4(a5)
    80005cc4:	60a2                	ld	ra,8(sp)
    80005cc6:	6402                	ld	s0,0(sp)
    80005cc8:	0141                	addi	sp,sp,16
    80005cca:	8082                	ret

0000000080005ccc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ccc:	1101                	addi	sp,sp,-32
    80005cce:	ec06                	sd	ra,24(sp)
    80005cd0:	e822                	sd	s0,16(sp)
    80005cd2:	e426                	sd	s1,8(sp)
    80005cd4:	1000                	addi	s0,sp,32
    80005cd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005cd8:	ffffc097          	auipc	ra,0xffffc
    80005cdc:	ca8080e7          	jalr	-856(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ce0:	00d5151b          	slliw	a0,a0,0xd
    80005ce4:	0c2017b7          	lui	a5,0xc201
    80005ce8:	97aa                	add	a5,a5,a0
    80005cea:	c3c4                	sw	s1,4(a5)
}
    80005cec:	60e2                	ld	ra,24(sp)
    80005cee:	6442                	ld	s0,16(sp)
    80005cf0:	64a2                	ld	s1,8(sp)
    80005cf2:	6105                	addi	sp,sp,32
    80005cf4:	8082                	ret

0000000080005cf6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005cf6:	1141                	addi	sp,sp,-16
    80005cf8:	e406                	sd	ra,8(sp)
    80005cfa:	e022                	sd	s0,0(sp)
    80005cfc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005cfe:	479d                	li	a5,7
    80005d00:	04a7cc63          	blt	a5,a0,80005d58 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d04:	0001c797          	auipc	a5,0x1c
    80005d08:	f3c78793          	addi	a5,a5,-196 # 80021c40 <disk>
    80005d0c:	97aa                	add	a5,a5,a0
    80005d0e:	0187c783          	lbu	a5,24(a5)
    80005d12:	ebb9                	bnez	a5,80005d68 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d14:	00451693          	slli	a3,a0,0x4
    80005d18:	0001c797          	auipc	a5,0x1c
    80005d1c:	f2878793          	addi	a5,a5,-216 # 80021c40 <disk>
    80005d20:	6398                	ld	a4,0(a5)
    80005d22:	9736                	add	a4,a4,a3
    80005d24:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005d28:	6398                	ld	a4,0(a5)
    80005d2a:	9736                	add	a4,a4,a3
    80005d2c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005d30:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005d34:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005d38:	97aa                	add	a5,a5,a0
    80005d3a:	4705                	li	a4,1
    80005d3c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005d40:	0001c517          	auipc	a0,0x1c
    80005d44:	f1850513          	addi	a0,a0,-232 # 80021c58 <disk+0x18>
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	370080e7          	jalr	880(ra) # 800020b8 <wakeup>
}
    80005d50:	60a2                	ld	ra,8(sp)
    80005d52:	6402                	ld	s0,0(sp)
    80005d54:	0141                	addi	sp,sp,16
    80005d56:	8082                	ret
    panic("free_desc 1");
    80005d58:	00003517          	auipc	a0,0x3
    80005d5c:	a0850513          	addi	a0,a0,-1528 # 80008760 <syscalls+0x2f8>
    80005d60:	ffffa097          	auipc	ra,0xffffa
    80005d64:	7e0080e7          	jalr	2016(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005d68:	00003517          	auipc	a0,0x3
    80005d6c:	a0850513          	addi	a0,a0,-1528 # 80008770 <syscalls+0x308>
    80005d70:	ffffa097          	auipc	ra,0xffffa
    80005d74:	7d0080e7          	jalr	2000(ra) # 80000540 <panic>

0000000080005d78 <virtio_disk_init>:
{
    80005d78:	1101                	addi	sp,sp,-32
    80005d7a:	ec06                	sd	ra,24(sp)
    80005d7c:	e822                	sd	s0,16(sp)
    80005d7e:	e426                	sd	s1,8(sp)
    80005d80:	e04a                	sd	s2,0(sp)
    80005d82:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d84:	00003597          	auipc	a1,0x3
    80005d88:	9fc58593          	addi	a1,a1,-1540 # 80008780 <syscalls+0x318>
    80005d8c:	0001c517          	auipc	a0,0x1c
    80005d90:	fdc50513          	addi	a0,a0,-36 # 80021d68 <disk+0x128>
    80005d94:	ffffb097          	auipc	ra,0xffffb
    80005d98:	db2080e7          	jalr	-590(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005d9c:	100017b7          	lui	a5,0x10001
    80005da0:	4398                	lw	a4,0(a5)
    80005da2:	2701                	sext.w	a4,a4
    80005da4:	747277b7          	lui	a5,0x74727
    80005da8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dac:	14f71b63          	bne	a4,a5,80005f02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005db0:	100017b7          	lui	a5,0x10001
    80005db4:	43dc                	lw	a5,4(a5)
    80005db6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005db8:	4709                	li	a4,2
    80005dba:	14e79463          	bne	a5,a4,80005f02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dbe:	100017b7          	lui	a5,0x10001
    80005dc2:	479c                	lw	a5,8(a5)
    80005dc4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005dc6:	12e79e63          	bne	a5,a4,80005f02 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dca:	100017b7          	lui	a5,0x10001
    80005dce:	47d8                	lw	a4,12(a5)
    80005dd0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dd2:	554d47b7          	lui	a5,0x554d4
    80005dd6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dda:	12f71463          	bne	a4,a5,80005f02 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dde:	100017b7          	lui	a5,0x10001
    80005de2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005de6:	4705                	li	a4,1
    80005de8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dea:	470d                	li	a4,3
    80005dec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dee:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005df0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005df4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc9df>
    80005df8:	8f75                	and	a4,a4,a3
    80005dfa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dfc:	472d                	li	a4,11
    80005dfe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e00:	5bbc                	lw	a5,112(a5)
    80005e02:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e06:	8ba1                	andi	a5,a5,8
    80005e08:	10078563          	beqz	a5,80005f12 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e0c:	100017b7          	lui	a5,0x10001
    80005e10:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e14:	43fc                	lw	a5,68(a5)
    80005e16:	2781                	sext.w	a5,a5
    80005e18:	10079563          	bnez	a5,80005f22 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e1c:	100017b7          	lui	a5,0x10001
    80005e20:	5bdc                	lw	a5,52(a5)
    80005e22:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e24:	10078763          	beqz	a5,80005f32 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005e28:	471d                	li	a4,7
    80005e2a:	10f77c63          	bgeu	a4,a5,80005f42 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005e2e:	ffffb097          	auipc	ra,0xffffb
    80005e32:	cb8080e7          	jalr	-840(ra) # 80000ae6 <kalloc>
    80005e36:	0001c497          	auipc	s1,0x1c
    80005e3a:	e0a48493          	addi	s1,s1,-502 # 80021c40 <disk>
    80005e3e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005e40:	ffffb097          	auipc	ra,0xffffb
    80005e44:	ca6080e7          	jalr	-858(ra) # 80000ae6 <kalloc>
    80005e48:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005e4a:	ffffb097          	auipc	ra,0xffffb
    80005e4e:	c9c080e7          	jalr	-868(ra) # 80000ae6 <kalloc>
    80005e52:	87aa                	mv	a5,a0
    80005e54:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005e56:	6088                	ld	a0,0(s1)
    80005e58:	cd6d                	beqz	a0,80005f52 <virtio_disk_init+0x1da>
    80005e5a:	0001c717          	auipc	a4,0x1c
    80005e5e:	dee73703          	ld	a4,-530(a4) # 80021c48 <disk+0x8>
    80005e62:	cb65                	beqz	a4,80005f52 <virtio_disk_init+0x1da>
    80005e64:	c7fd                	beqz	a5,80005f52 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005e66:	6605                	lui	a2,0x1
    80005e68:	4581                	li	a1,0
    80005e6a:	ffffb097          	auipc	ra,0xffffb
    80005e6e:	e68080e7          	jalr	-408(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005e72:	0001c497          	auipc	s1,0x1c
    80005e76:	dce48493          	addi	s1,s1,-562 # 80021c40 <disk>
    80005e7a:	6605                	lui	a2,0x1
    80005e7c:	4581                	li	a1,0
    80005e7e:	6488                	ld	a0,8(s1)
    80005e80:	ffffb097          	auipc	ra,0xffffb
    80005e84:	e52080e7          	jalr	-430(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005e88:	6605                	lui	a2,0x1
    80005e8a:	4581                	li	a1,0
    80005e8c:	6888                	ld	a0,16(s1)
    80005e8e:	ffffb097          	auipc	ra,0xffffb
    80005e92:	e44080e7          	jalr	-444(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e96:	100017b7          	lui	a5,0x10001
    80005e9a:	4721                	li	a4,8
    80005e9c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005e9e:	4098                	lw	a4,0(s1)
    80005ea0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005ea4:	40d8                	lw	a4,4(s1)
    80005ea6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005eaa:	6498                	ld	a4,8(s1)
    80005eac:	0007069b          	sext.w	a3,a4
    80005eb0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005eb4:	9701                	srai	a4,a4,0x20
    80005eb6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005eba:	6898                	ld	a4,16(s1)
    80005ebc:	0007069b          	sext.w	a3,a4
    80005ec0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005ec4:	9701                	srai	a4,a4,0x20
    80005ec6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005eca:	4705                	li	a4,1
    80005ecc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005ece:	00e48c23          	sb	a4,24(s1)
    80005ed2:	00e48ca3          	sb	a4,25(s1)
    80005ed6:	00e48d23          	sb	a4,26(s1)
    80005eda:	00e48da3          	sb	a4,27(s1)
    80005ede:	00e48e23          	sb	a4,28(s1)
    80005ee2:	00e48ea3          	sb	a4,29(s1)
    80005ee6:	00e48f23          	sb	a4,30(s1)
    80005eea:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005eee:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef2:	0727a823          	sw	s2,112(a5)
}
    80005ef6:	60e2                	ld	ra,24(sp)
    80005ef8:	6442                	ld	s0,16(sp)
    80005efa:	64a2                	ld	s1,8(sp)
    80005efc:	6902                	ld	s2,0(sp)
    80005efe:	6105                	addi	sp,sp,32
    80005f00:	8082                	ret
    panic("could not find virtio disk");
    80005f02:	00003517          	auipc	a0,0x3
    80005f06:	88e50513          	addi	a0,a0,-1906 # 80008790 <syscalls+0x328>
    80005f0a:	ffffa097          	auipc	ra,0xffffa
    80005f0e:	636080e7          	jalr	1590(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f12:	00003517          	auipc	a0,0x3
    80005f16:	89e50513          	addi	a0,a0,-1890 # 800087b0 <syscalls+0x348>
    80005f1a:	ffffa097          	auipc	ra,0xffffa
    80005f1e:	626080e7          	jalr	1574(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	8ae50513          	addi	a0,a0,-1874 # 800087d0 <syscalls+0x368>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	616080e7          	jalr	1558(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	8be50513          	addi	a0,a0,-1858 # 800087f0 <syscalls+0x388>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	606080e7          	jalr	1542(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005f42:	00003517          	auipc	a0,0x3
    80005f46:	8ce50513          	addi	a0,a0,-1842 # 80008810 <syscalls+0x3a8>
    80005f4a:	ffffa097          	auipc	ra,0xffffa
    80005f4e:	5f6080e7          	jalr	1526(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005f52:	00003517          	auipc	a0,0x3
    80005f56:	8de50513          	addi	a0,a0,-1826 # 80008830 <syscalls+0x3c8>
    80005f5a:	ffffa097          	auipc	ra,0xffffa
    80005f5e:	5e6080e7          	jalr	1510(ra) # 80000540 <panic>

0000000080005f62 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f62:	7119                	addi	sp,sp,-128
    80005f64:	fc86                	sd	ra,120(sp)
    80005f66:	f8a2                	sd	s0,112(sp)
    80005f68:	f4a6                	sd	s1,104(sp)
    80005f6a:	f0ca                	sd	s2,96(sp)
    80005f6c:	ecce                	sd	s3,88(sp)
    80005f6e:	e8d2                	sd	s4,80(sp)
    80005f70:	e4d6                	sd	s5,72(sp)
    80005f72:	e0da                	sd	s6,64(sp)
    80005f74:	fc5e                	sd	s7,56(sp)
    80005f76:	f862                	sd	s8,48(sp)
    80005f78:	f466                	sd	s9,40(sp)
    80005f7a:	f06a                	sd	s10,32(sp)
    80005f7c:	ec6e                	sd	s11,24(sp)
    80005f7e:	0100                	addi	s0,sp,128
    80005f80:	8aaa                	mv	s5,a0
    80005f82:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f84:	00c52d03          	lw	s10,12(a0)
    80005f88:	001d1d1b          	slliw	s10,s10,0x1
    80005f8c:	1d02                	slli	s10,s10,0x20
    80005f8e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80005f92:	0001c517          	auipc	a0,0x1c
    80005f96:	dd650513          	addi	a0,a0,-554 # 80021d68 <disk+0x128>
    80005f9a:	ffffb097          	auipc	ra,0xffffb
    80005f9e:	c3c080e7          	jalr	-964(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80005fa2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fa4:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005fa6:	0001cb97          	auipc	s7,0x1c
    80005faa:	c9ab8b93          	addi	s7,s7,-870 # 80021c40 <disk>
  for(int i = 0; i < 3; i++){
    80005fae:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005fb0:	0001cc97          	auipc	s9,0x1c
    80005fb4:	db8c8c93          	addi	s9,s9,-584 # 80021d68 <disk+0x128>
    80005fb8:	a08d                	j	8000601a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80005fba:	00fb8733          	add	a4,s7,a5
    80005fbe:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005fc2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005fc4:	0207c563          	bltz	a5,80005fee <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80005fc8:	2905                	addiw	s2,s2,1
    80005fca:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005fcc:	05690c63          	beq	s2,s6,80006024 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80005fd0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005fd2:	0001c717          	auipc	a4,0x1c
    80005fd6:	c6e70713          	addi	a4,a4,-914 # 80021c40 <disk>
    80005fda:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005fdc:	01874683          	lbu	a3,24(a4)
    80005fe0:	fee9                	bnez	a3,80005fba <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80005fe2:	2785                	addiw	a5,a5,1
    80005fe4:	0705                	addi	a4,a4,1
    80005fe6:	fe979be3          	bne	a5,s1,80005fdc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80005fea:	57fd                	li	a5,-1
    80005fec:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005fee:	01205d63          	blez	s2,80006008 <virtio_disk_rw+0xa6>
    80005ff2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005ff4:	000a2503          	lw	a0,0(s4)
    80005ff8:	00000097          	auipc	ra,0x0
    80005ffc:	cfe080e7          	jalr	-770(ra) # 80005cf6 <free_desc>
      for(int j = 0; j < i; j++)
    80006000:	2d85                	addiw	s11,s11,1
    80006002:	0a11                	addi	s4,s4,4
    80006004:	ff2d98e3          	bne	s11,s2,80005ff4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006008:	85e6                	mv	a1,s9
    8000600a:	0001c517          	auipc	a0,0x1c
    8000600e:	c4e50513          	addi	a0,a0,-946 # 80021c58 <disk+0x18>
    80006012:	ffffc097          	auipc	ra,0xffffc
    80006016:	042080e7          	jalr	66(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    8000601a:	f8040a13          	addi	s4,s0,-128
{
    8000601e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006020:	894e                	mv	s2,s3
    80006022:	b77d                	j	80005fd0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006024:	f8042503          	lw	a0,-128(s0)
    80006028:	00a50713          	addi	a4,a0,10
    8000602c:	0712                	slli	a4,a4,0x4

  if(write)
    8000602e:	0001c797          	auipc	a5,0x1c
    80006032:	c1278793          	addi	a5,a5,-1006 # 80021c40 <disk>
    80006036:	00e786b3          	add	a3,a5,a4
    8000603a:	01803633          	snez	a2,s8
    8000603e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006040:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006044:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006048:	f6070613          	addi	a2,a4,-160
    8000604c:	6394                	ld	a3,0(a5)
    8000604e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006050:	00870593          	addi	a1,a4,8
    80006054:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006056:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006058:	0007b803          	ld	a6,0(a5)
    8000605c:	9642                	add	a2,a2,a6
    8000605e:	46c1                	li	a3,16
    80006060:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006062:	4585                	li	a1,1
    80006064:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006068:	f8442683          	lw	a3,-124(s0)
    8000606c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006070:	0692                	slli	a3,a3,0x4
    80006072:	9836                	add	a6,a6,a3
    80006074:	058a8613          	addi	a2,s5,88
    80006078:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000607c:	0007b803          	ld	a6,0(a5)
    80006080:	96c2                	add	a3,a3,a6
    80006082:	40000613          	li	a2,1024
    80006086:	c690                	sw	a2,8(a3)
  if(write)
    80006088:	001c3613          	seqz	a2,s8
    8000608c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006090:	00166613          	ori	a2,a2,1
    80006094:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006098:	f8842603          	lw	a2,-120(s0)
    8000609c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800060a0:	00250693          	addi	a3,a0,2
    800060a4:	0692                	slli	a3,a3,0x4
    800060a6:	96be                	add	a3,a3,a5
    800060a8:	58fd                	li	a7,-1
    800060aa:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060ae:	0612                	slli	a2,a2,0x4
    800060b0:	9832                	add	a6,a6,a2
    800060b2:	f9070713          	addi	a4,a4,-112
    800060b6:	973e                	add	a4,a4,a5
    800060b8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800060bc:	6398                	ld	a4,0(a5)
    800060be:	9732                	add	a4,a4,a2
    800060c0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800060c2:	4609                	li	a2,2
    800060c4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800060c8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800060cc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800060d0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800060d4:	6794                	ld	a3,8(a5)
    800060d6:	0026d703          	lhu	a4,2(a3)
    800060da:	8b1d                	andi	a4,a4,7
    800060dc:	0706                	slli	a4,a4,0x1
    800060de:	96ba                	add	a3,a3,a4
    800060e0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800060e4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800060e8:	6798                	ld	a4,8(a5)
    800060ea:	00275783          	lhu	a5,2(a4)
    800060ee:	2785                	addiw	a5,a5,1
    800060f0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800060f4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800060f8:	100017b7          	lui	a5,0x10001
    800060fc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006100:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006104:	0001c917          	auipc	s2,0x1c
    80006108:	c6490913          	addi	s2,s2,-924 # 80021d68 <disk+0x128>
  while(b->disk == 1) {
    8000610c:	4485                	li	s1,1
    8000610e:	00b79c63          	bne	a5,a1,80006126 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006112:	85ca                	mv	a1,s2
    80006114:	8556                	mv	a0,s5
    80006116:	ffffc097          	auipc	ra,0xffffc
    8000611a:	f3e080e7          	jalr	-194(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    8000611e:	004aa783          	lw	a5,4(s5)
    80006122:	fe9788e3          	beq	a5,s1,80006112 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006126:	f8042903          	lw	s2,-128(s0)
    8000612a:	00290713          	addi	a4,s2,2
    8000612e:	0712                	slli	a4,a4,0x4
    80006130:	0001c797          	auipc	a5,0x1c
    80006134:	b1078793          	addi	a5,a5,-1264 # 80021c40 <disk>
    80006138:	97ba                	add	a5,a5,a4
    8000613a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000613e:	0001c997          	auipc	s3,0x1c
    80006142:	b0298993          	addi	s3,s3,-1278 # 80021c40 <disk>
    80006146:	00491713          	slli	a4,s2,0x4
    8000614a:	0009b783          	ld	a5,0(s3)
    8000614e:	97ba                	add	a5,a5,a4
    80006150:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006154:	854a                	mv	a0,s2
    80006156:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000615a:	00000097          	auipc	ra,0x0
    8000615e:	b9c080e7          	jalr	-1124(ra) # 80005cf6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006162:	8885                	andi	s1,s1,1
    80006164:	f0ed                	bnez	s1,80006146 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006166:	0001c517          	auipc	a0,0x1c
    8000616a:	c0250513          	addi	a0,a0,-1022 # 80021d68 <disk+0x128>
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	b1c080e7          	jalr	-1252(ra) # 80000c8a <release>
}
    80006176:	70e6                	ld	ra,120(sp)
    80006178:	7446                	ld	s0,112(sp)
    8000617a:	74a6                	ld	s1,104(sp)
    8000617c:	7906                	ld	s2,96(sp)
    8000617e:	69e6                	ld	s3,88(sp)
    80006180:	6a46                	ld	s4,80(sp)
    80006182:	6aa6                	ld	s5,72(sp)
    80006184:	6b06                	ld	s6,64(sp)
    80006186:	7be2                	ld	s7,56(sp)
    80006188:	7c42                	ld	s8,48(sp)
    8000618a:	7ca2                	ld	s9,40(sp)
    8000618c:	7d02                	ld	s10,32(sp)
    8000618e:	6de2                	ld	s11,24(sp)
    80006190:	6109                	addi	sp,sp,128
    80006192:	8082                	ret

0000000080006194 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006194:	1101                	addi	sp,sp,-32
    80006196:	ec06                	sd	ra,24(sp)
    80006198:	e822                	sd	s0,16(sp)
    8000619a:	e426                	sd	s1,8(sp)
    8000619c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000619e:	0001c497          	auipc	s1,0x1c
    800061a2:	aa248493          	addi	s1,s1,-1374 # 80021c40 <disk>
    800061a6:	0001c517          	auipc	a0,0x1c
    800061aa:	bc250513          	addi	a0,a0,-1086 # 80021d68 <disk+0x128>
    800061ae:	ffffb097          	auipc	ra,0xffffb
    800061b2:	a28080e7          	jalr	-1496(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061b6:	10001737          	lui	a4,0x10001
    800061ba:	533c                	lw	a5,96(a4)
    800061bc:	8b8d                	andi	a5,a5,3
    800061be:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800061c0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800061c4:	689c                	ld	a5,16(s1)
    800061c6:	0204d703          	lhu	a4,32(s1)
    800061ca:	0027d783          	lhu	a5,2(a5)
    800061ce:	04f70863          	beq	a4,a5,8000621e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800061d2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800061d6:	6898                	ld	a4,16(s1)
    800061d8:	0204d783          	lhu	a5,32(s1)
    800061dc:	8b9d                	andi	a5,a5,7
    800061de:	078e                	slli	a5,a5,0x3
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800061e4:	00278713          	addi	a4,a5,2
    800061e8:	0712                	slli	a4,a4,0x4
    800061ea:	9726                	add	a4,a4,s1
    800061ec:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800061f0:	e721                	bnez	a4,80006238 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800061f2:	0789                	addi	a5,a5,2
    800061f4:	0792                	slli	a5,a5,0x4
    800061f6:	97a6                	add	a5,a5,s1
    800061f8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800061fa:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800061fe:	ffffc097          	auipc	ra,0xffffc
    80006202:	eba080e7          	jalr	-326(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    80006206:	0204d783          	lhu	a5,32(s1)
    8000620a:	2785                	addiw	a5,a5,1
    8000620c:	17c2                	slli	a5,a5,0x30
    8000620e:	93c1                	srli	a5,a5,0x30
    80006210:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006214:	6898                	ld	a4,16(s1)
    80006216:	00275703          	lhu	a4,2(a4)
    8000621a:	faf71ce3          	bne	a4,a5,800061d2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000621e:	0001c517          	auipc	a0,0x1c
    80006222:	b4a50513          	addi	a0,a0,-1206 # 80021d68 <disk+0x128>
    80006226:	ffffb097          	auipc	ra,0xffffb
    8000622a:	a64080e7          	jalr	-1436(ra) # 80000c8a <release>
}
    8000622e:	60e2                	ld	ra,24(sp)
    80006230:	6442                	ld	s0,16(sp)
    80006232:	64a2                	ld	s1,8(sp)
    80006234:	6105                	addi	sp,sp,32
    80006236:	8082                	ret
      panic("virtio_disk_intr status");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	61050513          	addi	a0,a0,1552 # 80008848 <syscalls+0x3e0>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	300080e7          	jalr	768(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
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
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
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
