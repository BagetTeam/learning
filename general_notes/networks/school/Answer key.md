# Answer key

Worked solutions for every part, with the key steps a marker would look for. Try the exam first.

## 1. Short answers

**(a)** UDP: **one** socket. UDP demultiplexes on the destination port (with the destination IP) only, so segments from different sources with the same destination port reach the same socket. TCP: **two** sockets. A TCP connection socket is identified by the 4-tuple (source IP, source port, destination IP, destination port); the source IPs differ, so the segments go to different sockets.

**(b)** Add the first two words; there is no carry out of the top bit:

```
  0110 0110 0110 0000
+ 0101 0101 0101 0101
= 1011 1011 1011 0101
```

Add the third word; this time there is a carry, which wraps around:

```
  1011 1011 1011 0101
+ 1000 1111 0000 1100
= 1 0100 1010 1100 0001   (17 bits)
wraparound: 0100 1010 1100 0001 + 1 = 0100 1010 1100 0010   (sum)
checksum = complement of sum = 1011 0101 0011 1101
```

**(c)** No. A matching checksum means no error was *detected*. Example: the least-significant bit of word 1 flips 0 → 1 and the least-significant bit of word 2 flips 1 → 0. One word goes up by 1 and the other goes down by 1, so the sum and checksum do not change.

**(d)** Flow control stops one sender from overflowing one receiver's socket buffer; it uses **rwnd**, the receive-window field in the TCP header. Congestion control stops too many senders sending too fast for the network (router buffers and links); it uses **cwnd**, a variable kept at the sender. The sender keeps LastByteSent − LastByteAcked within both limits.

**(e)** Stop-and-wait has at most one unacknowledged packet. The receiver only has to tell the next new packet from a retransmission of the previous one, and these alternate between 0 and 1. A packet with the unexpected number is a duplicate: the receiver does **not** deliver it again, but it **re-sends the ACK** for it. Otherwise a sender whose ACK was corrupted or lost would retransmit forever.

**(f)** Any two of the following: no connection setup (saves an RTT); no connection state at sender or receiver; small 8-byte header; no congestion control, so the app can send at the rate it needs; loss-tolerant apps do not need retransmission. Needed reliability (and congestion control) must be added at the **application layer**, as HTTP/3 does.

**(g)** Since δ\[2 − n\] = δ\[n − 2\], the sum picks out n = 2, so S1 = 2² + 1 = **5**. In S2, δ\[k + 1\] is nonzero only at k = −1, which lies in the range k ≤ 3, so S2 = **1**.

**(h)** x1: E = Σ (0.25)^n over n ≥ 0 = 1/(1 − 0.25) = **4/3**, and P = 0, so it is an **energy signal**. x2: |x2\[n\]| = 3 for every n, so E = ∞ and P = **9**, a **power signal**.

**(i)** x3: 11π/4 − 2π = **3π/4**. Since Ω/2π = 11/8 in lowest terms, the fundamental period is **N = 8**. x4: 9π/5 − 2π = −π/5, and cosine is even, so x4\[n\] = cos(πn/5). Since Ω/2π = 9/10, the fundamental period is **N = 10**.

**(j)** At fs = 8 kHz, the Nyquist frequency is 4 kHz > 3 kHz, so **3 kHz** is reconstructed. At fs = 5 kHz, the Nyquist frequency is 2.5 kHz < 3 kHz, so the tone aliases to |3 − 5| = **2 kHz**.

**(k)** (i) **No.** Y(ω) = X(ω)H(ω), and X(ω) is zero except at ±4 rad/s, so an LTI system cannot create a component at 8 rad/s. (ii) **Yes.** cos²(4t) = ½ + ½ cos(8t). The squarer is nonlinear and creates new frequencies (8 rad/s and DC).

**(l)** Use e^(−3t)u(t) ↔ 1/(3 + jω) and a time shift of 2:

```latex
X(\omega)=\frac{e^{-j2\omega}}{3+j\omega},\qquad |X(3)|=\frac{1}{\sqrt{18}}=\frac{1}{3\sqrt2}\approx0.236,\qquad \arg X(3)=-2(3)-\tan^{-1}(1)=-6-\frac{\pi}{4}\approx-6.785\text{ rad}
```

Equivalently, the phase is −6.785 + 2π ≈ −0.502 rad. The shift changes only the phase; the magnitude is that of 1/(3 + jω).

## 2. Stop-and-wait, pipelining and window sizing

**(a)** L = 1,500 × 8 = 12,000 bits.

```latex
\frac{L}{R}=\frac{12{,}000}{100\times10^6}=0.12\text{ ms},\qquad \text{RTT}=2(10)=20\text{ ms},\qquad t_{\text{ACK}}=\text{RTT}+\frac{L}{R}=20.12\text{ ms}
```

**(b)** The sender is busy for L/R out of every RTT + L/R.

```latex
U=\frac{L/R}{\text{RTT}+L/R}=\frac{0.12}{20.12}\approx0.00596\ (0.596\%),\qquad \text{throughput}=\frac{L}{\text{RTT}+L/R}=\frac{12{,}000}{20.12\text{ ms}}\approx596\text{ kbit/s}
```

**(c)** With N packets per round trip:

```latex
U(N)=\frac{N\,L/R}{\text{RTT}+L/R}=\frac{0.12N}{20.12}\ \ge 0.9\ \Rightarrow\ N\ge\frac{0.9(20.12)}{0.12}=150.9\ \Rightarrow\ N=151
```

This gives U = 151(0.12)/20.12 ≈ 0.9006, so throughput ≈ 0.9006 × 100 = **90.06 Mbit/s**. The link stays continuously busy once N(L/R) ≥ RTT + L/R, that is N ≥ 20.12/0.12 = 167.7, so **N = 168**.

**(d)** For N = 151:

- Go-Back-N needs N ≤ 2^k − 1, so 2^k ≥ 152 and **k = 8**.
- Selective Repeat needs N ≤ 2^k / 2, so 2^k ≥ 302 and **k = 9**.

In Selective Repeat, the receiver's window can be up to N numbers ahead of the sender's window. If all ACKs are lost, the sender retransmits old packets while the receiver is already expecting new ones. If the sequence space has fewer than 2N numbers, an old retransmitted packet carries the same number as a new packet inside the receiver's window. The receiver cannot see the sender's side, so it wrongly accepts the old packet as new (the lecture's "oops" case with numbers 0–3 and window 3). A Go-Back-N receiver accepts only the single next in-order number, so N + 1 distinct numbers are enough.

**(e)** With R = 1 Gbit/s, L/R = 0.012 ms:

```latex
U=\frac{151(0.012)}{20.012}\approx0.0905\ (9.05\%),\qquad \text{throughput}=\frac{151(12{,}000)}{20.012\text{ ms}}\approx90.5\text{ Mbit/s}
```

Throughput barely changes because the **window** is now the limit, not the link: throughput ≈ N·L/RTT. To use a faster link the window must grow in proportion. This is the same idea as TCP's rate ≈ cwnd/RTT.

## 3. Go-Back-N and Selective Repeat

**(a) Go-Back-N.** The sender first sends pkt0 to pkt3 (window 0–3). Each new ACK slides the window and releases one new packet.

| Receiver gets | Receiver action | ACK sent | Sender response |
| --- | --- | --- | --- |
| pkt0 | deliver | ack0 | window 1–4, send pkt4 |
| pkt1 | deliver | ack1 | window 2–5, send pkt5 |
| (pkt2 lost) | — | — | — |
| pkt3 | out of order, discard | ack1 (duplicate) | ignore |
| pkt4 | discard | ack1 | ignore |
| pkt5 | discard | ack1 | ignore |

The window is stuck at 2–5. When pkt2's timer expires, the sender resends **pkt2, pkt3, pkt4 and pkt5**. Each now arrives in order and is delivered with ack2 to ack5. ack2 slides the window to 3–6, so **pkt6 is first sent after ack2 returns**, following the timeout. Transmissions: 6 originals (pkt0–pkt5) + 4 retransmissions + pkt6 = **11**.

**(b) Selective Repeat.**

| Receiver gets | Receiver action | ACK sent | Sender response |
| --- | --- | --- | --- |
| pkt0 | deliver | ack0 | window 1–4, send pkt4 |
| pkt1 | deliver | ack1 | window 2–5, send pkt5 |
| (pkt2 lost) | — | — | — |
| pkt3 | buffer | ack3 | mark 3 ACKed |
| pkt4 | buffer | ack4 | mark 4 ACKed |
| pkt5 | buffer | ack5 | mark 5 ACKed |

Just before the timeout the sender window is **{2, 3, 4, 5}**. Packets 3–5 are ACKed, but the base 2 is not, so the window cannot slide and **pkt6 (outside the window) cannot be sent**. On timeout, only **pkt2** is resent. The receiver then delivers pkt2, pkt3, pkt4 and pkt5 in order and sends ack2. ack2 moves the sender base past the already-ACKed 3–5 to 6, and pkt6 is sent. Transmissions: 6 + 1 + 1 = **8**.

**(c)** The receiver must **re-send ack1** even though 1 is below its window, and discard the duplicate data. If it ignored the packet, the sender, whose ack1 was delayed or lost, would never get an ACK for pkt1. Its window base would stay at 1, and it would keep retransmitting pkt1 and stall.

## 4. TCP sequence numbers, timers and flow control

**(a)** TCP numbers bytes, not segments.

1. Seg2: 500 + 80 = **580**. Seg3: 580 + 120 = **700**.
2. After Seg1, B expects byte 580, so it sends **ACK = 580**. Seg3 is out of order; it is buffered, and B again sends the cumulative **ACK = 580** (a duplicate ACK).
3. The retransmitted Seg2 fills the gap, so bytes 500–749 are all present. B sends **ACK = 750**.
4. **No.** ACK = 700 is cumulative, so it also confirms bytes 500–579 (Seg1). A moves SendBase to 700 and does not retransmit Seg1.

**(b)** Fast retransmit needs **four** ACKs with the same number: the original plus three duplicates ("triple duplicate ACKs"). A resends the unACKed segment with the smallest sequence number (here Seg2, sequence 580). Three duplicates mean three later segments arrived after a gap, so loss is likely and waiting for the timeout would only add delay.

**(c)** The update equations are:

```latex
\text{EstRTT}\leftarrow(1-\alpha)\,\text{EstRTT}+\alpha\,\text{SampleRTT},\quad \text{DevRTT}\leftarrow(1-\beta)\,\text{DevRTT}+\beta\,|\text{SampleRTT}-\text{EstRTT}|,\quad \text{Timeout}=\text{EstRTT}+4\,\text{DevRTT}
```

Sample 1 (140 ms):

```latex
\text{EstRTT}=0.875(100)+0.125(140)=105\text{ ms},\quad \text{DevRTT}=0.75(10)+0.25|140-105|=16.25\text{ ms},\quad \text{Timeout}=105+4(16.25)=170\text{ ms}
```

Sample 2 (90 ms):

```latex
\text{EstRTT}=0.875(105)+0.125(90)=103.125\text{ ms},\quad \text{DevRTT}=0.75(16.25)+0.25|90-103.125|=15.469\text{ ms},\quad \text{Timeout}=103.125+4(15.469)=165\text{ ms}
```

TCP ignores samples from retransmitted segments because an ACK does not say which copy it acknowledges. The original or the retransmission could have triggered it, so the measured time would be ambiguous.

**(d)**

| Segment | Flags | Seq | Ack |
| --- | --- | --- | --- |
| SYN (client → server) | SYN = 1 | 3000 | — |
| SYNACK (server → client) | SYN = 1, ACK = 1 | 9000 | 3001 |
| ACK (client → server) | ACK = 1 | 3001 | 9001 |

The SYN consumes one sequence number, so the first byte of client data carries **3001**. The third segment may already carry that data.

**(e)** rwnd = RcvBuffer − buffered data = 8,192 − 5,000 = **3,192 bytes**. The sender keeps LastByteSent − LastByteAcked ≤ rwnd, so it may send 3,192 − 2,000 = **1,192 more bytes** before a new ACK arrives.

## 5. TCP congestion control

**(a)** cwnd in MSS at the start of each round:

| Round | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| cwnd | 1 | 2 | 4 | 8 | 16 | 17 | 18 | 19 | 20 | 10 | 11 | 12 | 1 | 2 | 4 | 6 | 7 | 8 |
| ssthresh | 16 | 16 | 16 | 16 | 16 | 16 | 16 | 16 | 16 | 10 | 10 | 10 | 6 | 6 | 6 | 6 | 6 | 6 |

The steps behind the table:

- **Rounds 1–5:** doubling reaches ssthresh = 16 in round 5.
- **Rounds 6–9:** +1 per round, up to 20.
- **End of round 9 (triple duplicate ACK):** ssthresh = 20/2 = 10 and cwnd = 10.
- **Rounds 10–12:** +1 per round, up to 12.
- **End of round 12 (timeout):** ssthresh = 12/2 = 6 and cwnd = 1.
- **Rounds 13–16:** cwnd goes 1, 2, 4; the next doubling (8) would exceed 6, so round 16 has cwnd = 6.
- **Rounds 17–18:** +1 per round, giving 7 and 8.

**(b)** Slow start: rounds **1–4** and **13–15**. Congestion avoidance: rounds **5–12** and **16–18**. A triple duplicate ACK in Reno halves cwnd but stays in congestion avoidance. The switch to congestion avoidance happens when cwnd reaches ssthresh.

**(c)** ssthresh is **16** in round 6, **10** in round 11 and **6** in round 17.

**(d)** Tahoe treats the loss as a timeout: ssthresh = 20/2 = 10 and cwnd = 1. Rounds 10 to 14 then have cwnd = **1, 2, 4, 8, 10**. Round 14 is capped at ssthresh, since doubling 8 would give 16 > 10. ssthresh is **10** throughout.

**(e)** The rate in round 9 is:

```latex
\text{rate}\approx\frac{\text{cwnd}}{\text{RTT}}=\frac{20\times1460\times8\text{ bits}}{0.040\text{ s}}=5.84\text{ Mbit/s}
```

Rounds 1 to 5 send 1 + 2 + 4 + 8 + 16 = **31 segments**.

## 6. Fourier transform properties

**(a)** Split the integral at t = 0. For t < 0, |t| = −t; for t > 0, |t| = t.

```latex
X(\omega)=\int_{-\infty}^{0}e^{(a-j\omega)t}\,dt+\int_{0}^{\infty}e^{-(a+j\omega)t}\,dt=\frac{1}{a-j\omega}+\frac{1}{a+j\omega}=\frac{2a}{a^2+\omega^2}
```

Both boundary terms at ±∞ vanish because a > 0. X(ω) is **real** because x(t) is even: in e^(−jωt) = cos(ωt) − j sin(ωt), the odd sine part integrates to zero against an even signal. X(ω) is **even** because it depends only on ω². Its phase is 0 everywhere. At ω = 0, X(0) = **2/a**, the area under x(t).

With a = 2: X(ω) = 4/(4 + ω²).

**(b)** The four transforms:

1. Time shift: x(t − 3) ↔ e^(−j3ω) · 4/(4 + ω²). The magnitude spectrum is **unchanged**; only the phase −3ω is added.
2. Time scaling with b = 2: x(2t) ↔ ½ X(ω/2) = ½ · 4/(4 + ω²/4) = **8/(16 + ω²)**. Check: x(2t) = e^(−4|t|), which by part (a) with a = 4 has transform 2(4)/(16 + ω²) = 8/(16 + ω²). Compressing in time widens the spectrum.
3. Cosine modulation: x(t)cos(10t) ↔ ½\[X(ω − 10) + X(ω + 10)\] = 2/(4 + (ω − 10)²) + 2/(4 + (ω + 10)²).
4. Convolution: (x ∗ x)(t) ↔ X(ω)² = **16/(4 + ω²)²**.

**(c)** No. 4/(4 + ω²) is never zero, so the strict bandwidth is infinite. Since X(0) = 1, solve 4/(4 + ω²) = ½: 4 + ω² = 8, so **ω = 2 rad/s** (= a).

**(d)** The components are at 5 and 10 rad/s, so **ω0 = 5 rad/s** (T0 = 2π/5 s). By Euler's identity:

```latex
4\cos(5t)=2e^{j5t}+2e^{-j5t},\qquad -6\sin(10t)=-6\,\frac{e^{j10t}-e^{-j10t}}{2j}=3j\,e^{j10t}-3j\,e^{-j10t}
```

So D0 = 2, D1 = D−1 = 2, D2 = 3j and D−2 = −3j; all others are zero. Using S(ω) = 2π Σ Dn δ(ω − nω0):

```latex
S(\omega)=4\pi\,\delta(\omega)+4\pi\,\delta(\omega-5)+4\pi\,\delta(\omega+5)+6\pi j\,\delta(\omega-10)-6\pi j\,\delta(\omega+10)
```

Check: the weights at ±10 are complex conjugates, as they must be for a real signal.

## 7. Discrete-time signals and the DTFT

The nonzero samples are x\[0\], x\[1\], x\[2\], x\[3\] = 2, 1, −1, 3.

**(a)** E = 2² + 1² + (−1)² + 3² = **15**. P = lim 15/(2N + 1) = **0**. Finite, nonzero energy makes it an **energy signal**.

**(b)** The nonzero samples, listed as index: value:

| Sequence | Nonzero samples |
| --- | --- |
| x\[n + 1\] (advance by 1) | −1: 2, 0: 1, 1: −1, 2: 3 |
| x\[2 − n\] (reverse, then delay by 2) | −1: 3, 0: −1, 1: 1, 2: 2 |
| x\[2n\] (decimate by 2) | 0: 2, 1: −1 |
| z\[n\] (expand by 2) | 0: 2, 2: 1, 4: −1, 6: 3 |

For x\[2 − n\], sample k moves to n = 2 − k. Only **decimation** loses information: x\[1\] and x\[3\] are discarded. Shifts, reversal and expansion keep every sample.

**(c)** Since h\[n\] = δ\[n\] − δ\[n − 1\],

```latex
y[n]=\sum_{k}x[k]h[n-k]=x[n]-x[n-1]
```

This gives y\[0\] = 2, y\[1\] = 1 − 2 = −1, y\[2\] = −1 − 1 = −2, y\[3\] = 3 − (−1) = 4, y\[4\] = 0 − 3 = −3, and y\[n\] = 0 otherwise. The system is a **first difference**: it outputs the change between consecutive samples.

**(d)** The three transforms are:

```latex
X_d(\Omega)=2+e^{-j\Omega}-e^{-j2\Omega}+3e^{-j3\Omega},\qquad H_d(\Omega)=1-e^{-j\Omega}
```

```latex
Y_d(\Omega)=X_dH_d=2-e^{-j\Omega}-2e^{-j2\Omega}+4e^{-j3\Omega}-3e^{-j4\Omega}
```

The coefficients 2, −1, −2, 4, −3 match y\[0\] to y\[4\] from part (c). Also Xd(0) = 5 (sum of the samples) and Xd(π) = 2 − 1 − 1 − 3 = −3. Yd(0) = Xd(0)Hd(0) = 5 · 0 = **0**: the first difference has zero gain at DC, so the samples of y sum to zero. Factoring out e^(−jΩ/2):

```latex
H_d(\Omega)=e^{-j\Omega/2}\left(e^{j\Omega/2}-e^{-j\Omega/2}\right)=2j\,e^{-j\Omega/2}\sin(\Omega/2)\ \Rightarrow\ |H_d(\Omega)|=2|\sin(\Omega/2)|
```

The magnitude is 0 at Ω = 0 and 2 at Ω = ±π, so h\[n\] is a **highpass** filter.

**(e)** Write g\[n\] = (0.5)² (0.5)^(n−2) u\[n − 2\], a delayed geometric sequence scaled by 0.25:

```latex
G_d(\Omega)=0.25\,e^{-j2\Omega}\,\frac{1}{1-0.5e^{-j\Omega}}=\frac{0.25\,e^{-j2\Omega}}{1-0.5e^{-j\Omega}}
```

Check: Gd(0) = 0.25/0.5 = **0.5**, and the sum of samples is 0.25 + 0.125 + … = 0.25/(1 − 0.5) = 0.5. They agree.

**(f)** Each sequence in turn:

- x1: Ω/2π = 1/12, so it is periodic with **N1 = 12**.
- x2: Ω/2π = (4π/9)/(2π) = 2/9, so it is periodic with **N2 = 9**.
- x3: both terms repeat after lcm(12, 9) = 36. As in lecture, x3\[0\] = 2, and x3\[N\] = 2 only if both unit-magnitude terms equal 1, so N must be a multiple of both 12 and 9. **N3 = 36**.
- x4: Ω/2π = 1/(4π) is irrational, so x4 is **not periodic**.

## 8. Sampling and aliasing

**(a)** The highest frequency is 1100 Hz, so **B = 2π(1100) = 2200π rad/s** (≈ 6912 rad/s). The Nyquist rate is 2B = 4400π rad/s, or **2200 samples/s**. The sampler's Nyquist frequency is fs/2 = **500 Hz**. Since 1000 < 2200, **aliasing occurs**.

**(b)** With Ts = 1 ms, each term cos(2πf t) becomes cos(Ωn) with Ω = 2πf/fs:

| Term | Ω = 2πf/fs | Reduced to \[0, π\] |
| --- | --- | --- |
| 4cos(2π·300t) | 0.6π | 0.6π (already in range) |
| 2cos(2π·700t) | 1.4π | 1.4π − 2π = −0.6π; cosine is even → 0.6π |
| cos(2π·1100t) | 2.2π | 2.2π − 2π = 0.2π |

The 700 Hz samples land on the 300 Hz samples, so

```latex
x[n]=6\cos(0.6\pi n)+\cos(0.2\pi n).
```

**(c)** The cutoff is π/Ts = 1000π rad/s, which is **500 Hz**. Each discrete frequency Ω maps back to f = Ωfs/2π within |f| < 500 Hz:

```latex
x_r(t)=6\cos(2\pi\cdot300\,t)+\cos(2\pi\cdot100\,t)
```

**No component is recovered correctly.** The 300 Hz tone has the right frequency but amplitude 6 instead of 4, because the 700 Hz tone aliased onto it. The 700 Hz tone vanished as a separate component, and the 1100 Hz tone appears as a false 100 Hz tone.

**(d)** X(ω) has impulses at ±300, ±700 and ±1100 Hz, and sampling copies them to every k(1000) ± f:

| Original | Impulse locations in 0–2000 Hz |
| --- | --- |
| ±300 Hz | 300, 700, 1300, 1700 |
| ±700 Hz | 300, 700, 1300, 1700 |
| ±1100 Hz | 100, 900, 1100, 1900 |

The distinct locations are **100, 300, 700, 900, 1100, 1300, 1700 and 1900 Hz**. Only **100 Hz and 300 Hz** lie in the passband |f| < 500 Hz. The 300 Hz location holds both the original 300 Hz copy and the k = 1 copy of −700 Hz (1000 − 700). This is the overlap that produced amplitude 6 in part (c).

**(e)** Exact recovery needs fs **> 2200 samples/s**, strictly above the Nyquist rate. With an ideal 500 Hz anti-aliasing filter applied first, only 4cos(2π·300t) is sampled. It is below 500 Hz, so it is reconstructed exactly: **xr(t) = 4cos(2π·300t)**. The 700 and 1100 Hz content is lost, but nothing is corrupted by aliasing.

## 9. Systems and filtering

**(a)** The completed table:

| System | Memoryless | Causal | Linear | Time invariant | BIBO stable | Invertible |
| --- | --- | --- | --- | --- | --- | --- |
| S1: t·x(t) | Y | Y | Y | N | N | N |
| S2: x\[2n\] | N | N | Y | N | Y | N |
| S3: x(t) + 3 | Y | Y | N | Y | Y | Y |
| S4: accumulator | N | Y | Y | Y | N | Y |

Justification of each N:

- **S1, time invariant:** shifting the input gives t·x(t − t0), but shifting the output gives (t − t0)·x(t − t0).
- **S1, stable:** x(t) = 1 is bounded, but y(t) = t is not.
- **S1, invertible:** y(0) = 0 for every input, so x(0) cannot be recovered.
- **S2, memoryless and causal:** y\[1\] = x\[2\], a sample at a different, later time.
- **S2, time invariant:** the input x\[n − 1\] gives x\[2n − 1\], but y\[n − 1\] = x\[2n − 2\].
- **S2, invertible:** x\[n\] = δ\[n − 1\] and x\[n\] = 0 both give y\[n\] = 0, since odd samples are discarded.
- **S3, linear:** a zero input gives y = 3, not 0. Also H\[2x\] = 2x + 3 ≠ 2H\[x\] = 2x + 6.
- **S4, memoryless:** the output uses all past inputs.
- **S4, stable:** x\[n\] = u\[n\] gives y\[n\] = n + 1 for n ≥ 0, which is unbounded.

The Y entries hold for these reasons: S3 is stable since |y| ≤ Mx + 3, and invertible since x = y − 3. S4 is invertible since x\[n\] = y\[n\] − y\[n − 1\]. S2 is stable since |y\[n\]| ≤ Mx.

**(b)** The impulse response is the accumulated impulse, **h\[n\] = u\[n\]**. The response splits into two parts:

- **Zero-input** (x = 0, y\[−1\] = 2): y\[n\] = y\[n − 1\], so **yzi\[n\] = 2** for n ≥ 0.
- **Zero-state** (y\[−1\] = 0): yzs\[n\] = (x ∗ h)\[n\] = u\[n\] − u\[n − 3\], which is 1 for n = 0, 1, 2 and 0 for n ≥ 3.
- **Total:** y\[n\] = 2 + u\[n\] − u\[n − 3\] = **3, 3, 3, 2, 2, …** for n = 0, 1, 2, 3, 4, …

Check with the recursion: y\[0\] = 2 + 1 = 3, y\[1\] = 3, y\[2\] = 3, y\[3\] = 3 − 1 = 2. A nonzero initial state gives a nonzero output even with zero input.

**(c)** From e^(−at)u(t) ↔ 1/(a + jω), **H(ω) = 1/(2 + jω)**.

- DC component: H(0) = ½, so 3 becomes **3/2**.
- 2 rad/s component: |H(2)| = 1/√8 = 1/(2√2) ≈ 0.354 and arg H(2) = −tan⁻¹(2/2) = −π/4.

```latex
y(t)=\frac{3}{2}+\frac{1}{2\sqrt2}\cos\!\left(2t-\frac{\pi}{4}\right)
```

There is **no 4 rad/s component**: Y(ω) = X(ω)H(ω) is zero wherever X(ω) is, and an LTI system creates no new frequencies.

**(d)** h\[n\] = δ\[n\] + ½ δ\[n − 2\] and Hd(Ω) = 1 + ½ e^(−j2Ω). At Ω = 0, Hd = 3/2. At Ω = π/2, Hd = 1 + ½ e^(−jπ) = ½, which is real, so there is no phase shift. Therefore **y\[n\] = 3 + ½ cos(πn/2)**. Direct check: cos(π(n − 2)/2) = −cos(πn/2), so y\[n\] = 2 + cos(πn/2) + ½(2 − cos(πn/2)) = 3 + ½ cos(πn/2).

**(e)** Reduce each frequency to \[−π, π\] first:

- The constant 1 is at Ω = 0, which **passes**.
- cos(πn/4) is at π/4 < π/2, which **passes**.
- cos(7πn/4) = cos(−πn/4) = cos(πn/4): the frequency 7π/4 is equivalent to −π/4, so it **passes**.
- (−1)^n = cos(πn) is at Ω = π, which is **blocked**.

The output is **y\[n\] = 1 + 2cos(πn/4)**. The trap: 7π/4 looks like a high frequency but is equivalent to −π/4.
