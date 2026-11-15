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

**(d)** Flow control stops one sender from overflowing one receiver's socket buffer; it uses **rwnd**, the receive-window field in the TCP header. Congestion control stops too many senders sending too fast for the network (router buffers and links); it uses **cwnd**, a variable kept at the sender. The sender keeps $\mathrm{LastByteSent} - \mathrm{LastByteAcked}$ within both limits.

**(e)** Stop-and-wait has at most one unacknowledged packet. The receiver only has to tell the next new packet from a retransmission of the previous one, and these alternate between 0 and 1. A packet with the unexpected number is a duplicate: the receiver does **not** deliver it again, but it **re-sends the ACK** for it. Otherwise a sender whose ACK was corrupted or lost would retransmit forever.

**(f)** Any two of the following: no connection setup (saves an RTT); no connection state at sender or receiver; small 8-byte header; no congestion control, so the app can send at the rate it needs; loss-tolerant apps do not need retransmission. Needed reliability (and congestion control) must be added at the **application layer**, as HTTP/3 does.

**(g)** Since $\delta[2-n] = \delta[n-2]$, the sum picks out $n = 2$, so $S_1 = 2^2 + 1 = \mathbf{5}$. In $S_2$, $\delta[k+1]$ is nonzero only at $k = -1$, which lies in the range $k \le 3$, so $S_2 = \mathbf{1}$.

**(h)** $x_1$: $E = \sum_{n=0}^{\infty}(0.25)^n = \frac{1}{1-0.25} = \mathbf{\frac43}$, and $P = 0$, so it is an **energy signal**. $x_2$: $|x_2[n]| = 3$ for every n, so $E = \infty$ and $P = \mathbf{9}$, a **power signal**.

**(i)** $x_3$: $\frac{11\pi}{4} - 2\pi = \mathbf{\frac{3\pi}{4}}$. Since $\frac{\Omega}{2\pi} = \frac{11}{8}$ in lowest terms, the fundamental period is **$N = 8$**. $x_4$: $\frac{9\pi}{5} - 2\pi = -\frac{\pi}{5}$, and cosine is even, so $x_4[n] = \cos(\pi n/5)$. Since $\frac{\Omega}{2\pi} = \frac9{10}$, the fundamental period is **$N = 10$**.

**(j)** At $f_s = 8\,\text{kHz}$, the Nyquist frequency is $4\,\text{kHz} > 3\,\text{kHz}$, so **3 kHz** is reconstructed. At $f_s = 5\,\text{kHz}$, the Nyquist frequency is $2.5\,\text{kHz} < 3\,\text{kHz}$, so the tone aliases to $|3-5| = \mathbf{2}\,\text{kHz}$.

**(k)** (i) **No.** $Y(\omega) = X(\omega)H(\omega)$, and $X(\omega)$ is zero except at $\pm4$ rad/s, so an LTI system cannot create a component at 8 rad/s. (ii) **Yes.** $\cos^2(4t) = \tfrac12 + \tfrac12\cos(8t)$. The squarer is nonlinear and creates new frequencies (8 rad/s and DC).

**(l)** Use $e^{-3t}u(t) \longleftrightarrow \frac{1}{3+j\omega}$ and a time shift of 2:

$$
\begin{gathered}
X(\omega)=\frac{e^{-j2\omega}}{3+j\omega} \\
|X(3)|=\frac{1}{\sqrt{18}}=\frac{1}{3\sqrt2}\approx0.236 \\
\arg X(3)=-2(3)-\tan^{-1}(1)=-6-\frac{\pi}{4}\approx-6.785\text{ rad}
\end{gathered}
$$

Equivalently, the phase is $-6.785 + 2\pi \approx -0.502\,\text{rad}$. The shift changes only the phase; the magnitude is that of $\frac{1}{3+j\omega}$.

## 2. Stop-and-wait, pipelining and window sizing

**(a)** $L = 1{,}500 \times 8 = 12{,}000\,\text{bits}$.

$$
\begin{gathered}
\frac{L}{R}=\frac{12{,}000}{100\times10^6}=0.12\text{ ms} \\
\text{RTT}=2(10)=20\text{ ms} \\
t_{\text{ACK}}=\text{RTT}+\frac{L}{R}=20.12\text{ ms}
\end{gathered}
$$

**(b)** The sender is busy for $L/R$ out of every $\mathrm{RTT} + L/R$.

$$
\begin{gathered}
U=\frac{L/R}{\text{RTT}+L/R}=\frac{0.12}{20.12}\approx0.00596\ (0.596\%) \\
\text{throughput}=\frac{L}{\text{RTT}+L/R}=\frac{12{,}000}{20.12\text{ ms}}\approx596\text{ kbit/s}
\end{gathered}
$$

**(c)** With N packets per round trip:

$$
\begin{aligned}
U(N) &= \frac{N\,L/R}{\mathrm{RTT}+L/R} = \frac{0.12N}{20.12}, \\
U(N) \ge 0.9 &\implies N \ge \frac{0.9(20.12)}{0.12} = 150.9, \\
&\implies N = 151.
\end{aligned}
$$

This gives $U = \frac{151(0.12)}{20.12} \approx 0.9006$, so $\text{throughput} \approx 0.9006 \times 100 = \mathbf{90.06}\,\text{Mbit/s}$. The link stays continuously busy once $N(L/R) \ge \mathrm{RTT} + L/R$, that is $N \ge \frac{20.12}{0.12} = 167.7$, so **$N = 168$**.

**(d)** For $N = 151$:

- Go-Back-N needs $N \le 2^k - 1$, so $2^k \ge 152$ and **$k = 8$**.
- Selective Repeat needs $N \le \frac{2^k}{2}$, so $2^k \ge 302$ and **$k = 9$**.

In Selective Repeat, the receiver's window can be up to N numbers ahead of the sender's window. If all ACKs are lost, the sender retransmits old packets while the receiver is already expecting new ones. If the sequence space has fewer than $2N$ numbers, an old retransmitted packet carries the same number as a new packet inside the receiver's window. The receiver cannot see the sender's side, so it wrongly accepts the old packet as new (the lecture's "oops" case with numbers 0–3 and window 3). A Go-Back-N receiver accepts only the single next in-order number, so $N + 1$ distinct numbers are enough.

**(e)** With $R = 1\,\text{Gbit/s}$, $L/R = 0.012\,\text{ms}$:

$$
\begin{gathered}
U=\frac{151(0.012)}{20.012}\approx0.0905\ (9.05\%) \\
\text{throughput}=\frac{151(12{,}000)}{20.012\text{ ms}}\approx90.5\text{ Mbit/s}
\end{gathered}
$$

Throughput barely changes because the **window** is now the limit, not the link: $\text{throughput} \approx \frac{NL}{\mathrm{RTT}}$. To use a faster link the window must grow in proportion. This is the same idea as TCP's $\text{rate} \approx \frac{\mathrm{cwnd}}{\mathrm{RTT}}$.

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

The window is stuck at 2–5. When pkt2's timer expires, the sender resends **pkt2, pkt3, pkt4 and pkt5**. Each now arrives in order and is delivered with ack2 to ack5. ack2 slides the window to 3–6, so **pkt6 is first sent after ack2 returns**, following the timeout. Transmissions: $6+4+1=\mathbf{11}$ (6 originals, 4 retransmissions and pkt6).

**(b) Selective Repeat.**

| Receiver gets | Receiver action | ACK sent | Sender response |
| --- | --- | --- | --- |
| pkt0 | deliver | ack0 | window 1–4, send pkt4 |
| pkt1 | deliver | ack1 | window 2–5, send pkt5 |
| (pkt2 lost) | — | — | — |
| pkt3 | buffer | ack3 | mark 3 ACKed |
| pkt4 | buffer | ack4 | mark 4 ACKed |
| pkt5 | buffer | ack5 | mark 5 ACKed |

Just before the timeout the sender window is $\{2,3,4,5\}$. Packets 3–5 are ACKed, but the base 2 is not, so the window cannot slide and **pkt6 (outside the window) cannot be sent**. On timeout, only **pkt2** is resent. The receiver then delivers pkt2, pkt3, pkt4 and pkt5 in order and sends ack2. ack2 moves the sender base past the already-ACKed 3–5 to 6, and pkt6 is sent. Transmissions: $6+1+1 = \mathbf8$.

**(c)** The receiver must **re-send ack1** even though 1 is below its window, and discard the duplicate data. If it ignored the packet, the sender, whose ack1 was delayed or lost, would never get an ACK for pkt1. Its window base would stay at 1, and it would keep retransmitting pkt1 and stall.

## 4. TCP sequence numbers, timers and flow control

**(a)** TCP numbers bytes, not segments.

1. Seg2: $500 + 80 = \mathbf{580}$. Seg3: $580 + 120 = \mathbf{700}$.
2. After Seg1, B expects byte 580, so it sends **$\mathrm{ACK} = 580$**. Seg3 is out of order; it is buffered, and B again sends the cumulative **$\mathrm{ACK} = 580$** (a duplicate ACK).
3. The retransmitted Seg2 fills the gap, so bytes 500–749 are all present. B sends **$\mathrm{ACK} = 750$**.
4. **No.** $\mathrm{ACK} = 700$ is cumulative, so it also confirms bytes 500–579 (Seg1). A moves SendBase to 700 and does not retransmit Seg1.

**(b)** Fast retransmit needs **four** ACKs with the same number: the original plus three duplicates ("triple duplicate ACKs"). A resends the unACKed segment with the smallest sequence number (here Seg2, sequence 580). Three duplicates mean three later segments arrived after a gap, so loss is likely and waiting for the timeout would only add delay.

**(c)** The update equations are:

$$
\begin{gathered}
\text{EstRTT}\leftarrow(1-\alpha)\,\text{EstRTT}+\alpha\,\text{SampleRTT} \\
\text{DevRTT}\leftarrow(1-\beta)\,\text{DevRTT}+\beta\,|\text{SampleRTT}-\text{EstRTT}| \\
\text{Timeout}=\text{EstRTT}+4\,\text{DevRTT}
\end{gathered}
$$

Sample 1 (140 ms):

$$
\begin{gathered}
\text{EstRTT}=0.875(100)+0.125(140)=105\text{ ms} \\
\text{DevRTT}=0.75(10)+0.25|140-105|=16.25\text{ ms} \\
\text{Timeout}=105+4(16.25)=170\text{ ms}
\end{gathered}
$$

Sample 2 (90 ms):

$$
\begin{gathered}
\text{EstRTT}=0.875(105)+0.125(90)=103.125\text{ ms} \\
\text{DevRTT}=0.75(16.25)+0.25|90-103.125|=15.469\text{ ms} \\
\text{Timeout}=103.125+4(15.469)=165\text{ ms}
\end{gathered}
$$

TCP ignores samples from retransmitted segments because an ACK does not say which copy it acknowledges. The original or the retransmission could have triggered it, so the measured time would be ambiguous.

**(d)**

| Segment | Flags | Seq | Ack |
| --- | --- | --- | --- |
| SYN (client → server) | $\mathrm{SYN} = 1$ | 3000 | — |
| SYNACK (server → client) | $\mathrm{SYN} = 1$, $\mathrm{ACK} = 1$ | 9000 | 3001 |
| ACK (client → server) | $\mathrm{ACK} = 1$ | 3001 | 9001 |

The SYN consumes one sequence number, so the first byte of client data carries **3001**. The third segment may already carry that data.

**(e)** $\mathrm{rwnd} = \mathrm{RcvBuffer} - \text{buffered data} = 8{,}192 - 5{,}000 = \mathbf{3{,}192}\,\text{bytes}$. The sender keeps $\mathrm{LastByteSent} - \mathrm{LastByteAcked} \le \mathrm{rwnd}$, so it may send $3{,}192 - 2{,}000 = \mathbf{1{,}192}\,\text{more bytes}$ before a new ACK arrives.

## 5. TCP congestion control

**(a)** cwnd in MSS at the start of each round:

| Round | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| cwnd | 1 | 2 | 4 | 8 | 16 | 17 | 18 | 19 | 20 | 10 | 11 | 12 | 1 | 2 | 4 | 6 | 7 | 8 |
| ssthresh | 16 | 16 | 16 | 16 | 16 | 16 | 16 | 16 | 16 | 10 | 10 | 10 | 6 | 6 | 6 | 6 | 6 | 6 |

The steps behind the table:

- **Rounds 1–5:** doubling reaches $\mathrm{ssthresh} = 16$ in round 5.
- **Rounds 6–9:** +1 per round, up to 20.
- **End of round 9 (triple duplicate ACK):** $\mathrm{ssthresh} = \frac{20}{2} = 10$ and $\mathrm{cwnd} = 10$.
- **Rounds 10–12:** +1 per round, up to 12.
- **End of round 12 (timeout):** $\mathrm{ssthresh} = \frac{12}{2} = 6$ and $\mathrm{cwnd} = 1$.
- **Rounds 13–16:** cwnd goes 1, 2, 4; the next doubling (8) would exceed 6, so round 16 has $\mathrm{cwnd} = 6$.
- **Rounds 17–18:** +1 per round, giving 7 and 8.

**(b)** Slow start: rounds **1–4** and **13–15**. Congestion avoidance: rounds **5–12** and **16–18**. A triple duplicate ACK in Reno halves cwnd but stays in congestion avoidance. The switch to congestion avoidance happens when cwnd reaches ssthresh.

**(c)** ssthresh is **16** in round 6, **10** in round 11 and **6** in round 17.

**(d)** Tahoe treats the loss as a timeout: $\mathrm{ssthresh} = \frac{20}{2} = 10$ and $\mathrm{cwnd} = 1$. Rounds 10 to 14 then have $\mathrm{cwnd} = \mathbf{1,\ 2,\ 4,\ 8,\ 10}$. Round 14 is capped at ssthresh, since doubling 8 would give $16 > 10$. ssthresh is **10** throughout.

**(e)** The rate in round 9 is:

$$
\text{rate}\approx\frac{\text{cwnd}}{\text{RTT}}=\frac{20\times1460\times8\text{ bits}}{0.040\text{ s}}=5.84\text{ Mbit/s}
$$

Rounds 1 to 5 send $1 + 2 + 4 + 8 + 16 = \mathbf{31}\,\text{segments}$.

## 6. Fourier transform properties

**(a)** Split the integral at $t = 0$. For $t < 0$, $|t| = -t$; for $t > 0$, $|t| = t$.

$$
\begin{aligned}
X(\omega) &= \int_{-\infty}^{0}e^{(a-j\omega)t}\,dt
+ \int_{0}^{\infty}e^{-(a+j\omega)t}\,dt \\
&= \frac{1}{a-j\omega}+\frac{1}{a+j\omega} \\
&= \frac{2a}{a^2+\omega^2}.
\end{aligned}
$$

Both boundary terms at $\pm\infty$ vanish because $a > 0$. $X(\omega)$ is **real** because $x(t)$ is even: in $e^{-j\omega t} = \cos(\omega t) - j\sin(\omega t)$, the odd sine part integrates to zero against an even signal. $X(\omega)$ is **even** because it depends only on $\omega^2$. Its phase is 0 everywhere. At $\omega = 0$, $X(0) = \mathbf{\frac{2}{a}}$, the area under $x(t)$.

With $a = 2$: $X(\omega) = \frac{4}{4+\omega^2}$.

**(b)** The four transforms:

1. Time shift:

   $$
   x(t-3) \longleftrightarrow e^{-j3\omega}\frac{4}{4+\omega^2}.
   $$

   The magnitude spectrum is **unchanged**; only the phase $-3\omega$ is added.

2. Time scaling with $b = 2$:

   $$
   x(2t) \longleftrightarrow \frac12 X(\omega/2)
   = \frac12\frac{4}{4+\omega^2/4}
   = \mathbf{\frac{8}{16+\omega^2}}.
   $$

   Check: $x(2t) = e^{-4|t|}$, which by part (a) with $a = 4$ has transform $\frac{2(4)}{16+\omega^2} = \frac{8}{16+\omega^2}$. Compressing in time widens the spectrum.

3. Cosine modulation:

   $$
   \begin{aligned}
   x(t)\cos(10t) &\longleftrightarrow \tfrac12[X(\omega-10)+X(\omega+10)] \\
   &= \frac{2}{4+(\omega-10)^2}+\frac{2}{4+(\omega+10)^2}.
   \end{aligned}
   $$

4. Convolution:

   $$
   (x*x)(t) \longleftrightarrow X(\omega)^2
   = \mathbf{\frac{16}{(4+\omega^2)^2}}.
   $$

**(c)** No. $\frac{4}{4+\omega^2}$ is never zero, so the strict bandwidth is infinite. Since $X(0) = 1$, solve $\frac{4}{4+\omega^2} = \frac12$: $4+\omega^2 = 8$, so **$\omega = 2\,\text{rad/s}$** ($=a$).

**(d)** The components are at 5 and 10 rad/s, so **$\omega_0 = 5\,\text{rad/s}$** ($T_0 = \frac{2\pi}{5}\,\text{s}$). By Euler's identity:

$$
\begin{gathered}
4\cos(5t)=2e^{j5t}+2e^{-j5t} \\
-6\sin(10t)=-6\,\frac{e^{j10t}-e^{-j10t}}{2j}=3j\,e^{j10t}-3j\,e^{-j10t}
\end{gathered}
$$

So $D_0 = 2$, $D_1 = D_{-1} = 2$, $D_2 = 3j$ and $D_{-2} = -3j$; all others are zero. Using $S(\omega) = 2\pi\sum_{n=-\infty}^{\infty}D_n\delta(\omega-n\omega_0)$:

$$
\begin{aligned}
S(\omega) &= 4\pi\,\delta(\omega)
+4\pi\,\delta(\omega-5)+4\pi\,\delta(\omega+5) \\
&\quad +6\pi j\,\delta(\omega-10)-6\pi j\,\delta(\omega+10).
\end{aligned}
$$

Check: the weights at $\pm10$ are complex conjugates, as they must be for a real signal.

## 7. Discrete-time signals and the DTFT

The nonzero samples are $x[0],\ x[1],\ x[2],\ x[3] = 2,\ 1,\ -1,\ 3$.

**(a)** $E = 2^2+1^2+(-1)^2+3^2 = \mathbf{15}$. $P = \lim_{N\to\infty}\frac{15}{2N+1} = \mathbf{0}$. Finite, nonzero energy makes it an **energy signal**.

**(b)** The nonzero samples, listed as index: value:

| Sequence | Nonzero samples |
| --- | --- |
| $x[n + 1]$ (advance by 1) | −1: 2, 0: 1, 1: −1, 2: 3 |
| $x[2 - n]$ (reverse, then delay by 2) | −1: 3, 0: −1, 1: 1, 2: 2 |
| $x[2n]$ (decimate by 2) | 0: 2, 1: −1 |
| $z[n]$ (expand by 2) | 0: 2, 2: 1, 4: −1, 6: 3 |

For $x[2 - n]$, sample k moves to $n = 2-k$. Only **decimation** loses information: $x[1]$ and $x[3]$ are discarded. Shifts, reversal and expansion keep every sample.

**(c)** Since $h[n] = \delta[n]-\delta[n-1]$,

$$
y[n]=\sum_{k}x[k]h[n-k]=x[n]-x[n-1]
$$

This gives $y[0] = 2$, $y[1] = 1-2 = -1$, $y[2] = -1-1 = -2$, $y[3] = 3-(-1) = 4$, $y[4] = 0-3 = -3$, and $y[n] = 0$ otherwise. The system is a **first difference**: it outputs the change between consecutive samples.

**(d)** The three transforms are:

$$
\begin{gathered}
X_d(\Omega)=2+e^{-j\Omega}-e^{-j2\Omega}+3e^{-j3\Omega} \\
H_d(\Omega)=1-e^{-j\Omega}
\end{gathered}
$$

$$
Y_d(\Omega)=X_dH_d=2-e^{-j\Omega}-2e^{-j2\Omega}+4e^{-j3\Omega}-3e^{-j4\Omega}
$$

The coefficients 2, −1, −2, 4, −3 match $y[0]$ to $y[4]$ from part (c). Also $X_d(0) = 5$ (sum of the samples) and $X_d(\pi) = 2-1-1-3 = -3$. $Y_d(0) = X_d(0)H_d(0) = 5\cdot0 = \mathbf{0}$: the first difference has zero gain at DC, so the samples of y sum to zero. Factoring out $e^{-j\Omega/2}$:

$$
\begin{aligned}
H_d(\Omega) &= e^{-j\Omega/2}\left(e^{j\Omega/2}-e^{-j\Omega/2}\right) \\
&= 2j\,e^{-j\Omega/2}\sin(\Omega/2), \\
|H_d(\Omega)| &= 2|\sin(\Omega/2)|.
\end{aligned}
$$

The magnitude is 0 at $\Omega = 0$ and 2 at $\Omega = \pm\pi$, so $h[n]$ is a **highpass** filter.

**(e)** Write $g[n] = (0.5)^2(0.5)^{n-2}u[n-2]$, a delayed geometric sequence scaled by 0.25:

$$
G_d(\Omega)=0.25\,e^{-j2\Omega}\,\frac{1}{1-0.5e^{-j\Omega}}=\frac{0.25\,e^{-j2\Omega}}{1-0.5e^{-j\Omega}}
$$

Check: $G_d(0) = \frac{0.25}{0.5} = \mathbf{0.5}$, and the sum of samples is $0.25+0.125+\cdots = \frac{0.25}{1-0.5} = 0.5$. They agree.

**(f)** Each sequence in turn:

- $x_1$: $\frac{\Omega}{2\pi} = \frac1{12}$, so it is periodic with **$N_1 = 12$**.
- $x_2$: $\frac{\Omega}{2\pi} = \frac{4\pi/9}{2\pi} = \frac29$, so it is periodic with **$N_2 = 9$**.
- $x_3$: both terms repeat after $\operatorname{lcm}(12,9) = 36$. As in lecture, $x_3[0] = 2$, and $x_3[N] = 2$ only if both unit-magnitude terms equal 1, so N must be a multiple of both 12 and 9. **$N_3 = 36$**.
- $x_4$: $\frac{\Omega}{2\pi} = \frac1{4\pi}$ is irrational, so $x_4$ is **not periodic**.

## 8. Sampling and aliasing

**(a)** The highest frequency is 1100 Hz, so **$B = 2\pi(1100) = 2200\pi\,\text{rad/s}$** ($\approx 6912\,\text{rad/s}$). The Nyquist rate is $2B = 4400\pi\,\text{rad/s}$, or **2200 samples/s**. The sampler's Nyquist frequency is $\frac{f_s}{2} = \mathbf{500}\,\text{Hz}$. Since $1000 < 2200$, **aliasing occurs**.

**(b)** With $T_s = 1\,\text{ms}$, each term $\cos(2\pi f t)$ becomes $\cos(\Omega n)$ with $\Omega = \frac{2\pi f}{f_s}$:

| Term | $\Omega = \frac{2\pi f}{f_s}$ | Reduced to $[0,\pi]$ |
| --- | --- | --- |
| $4\cos(2\pi\cdot300t)$ | $0.6\pi$ | $0.6\pi$ (already in range) |
| $2\cos(2\pi\cdot700t)$ | $1.4\pi$ | $1.4\pi-2\pi = -0.6\pi$; cosine is even → $0.6\pi$ |
| $\cos(2\pi\cdot1100t)$ | $2.2\pi$ | $2.2\pi-2\pi = 0.2\pi$ |

The 700 Hz samples land on the 300 Hz samples, so

$$
x[n]=6\cos(0.6\pi n)+\cos(0.2\pi n).
$$

**(c)** The cutoff is $\frac{\pi}{T_s} = 1000\pi\,\text{rad/s}$, which is **500 Hz**. Each discrete frequency $\Omega$ maps back to $f = \frac{\Omega f_s}{2\pi}$ within $|f| < 500\,\text{Hz}$:

$$
x_r(t)=6\cos(2\pi\cdot300\,t)+\cos(2\pi\cdot100\,t)
$$

**No component is recovered correctly.** The 300 Hz tone has the right frequency but amplitude 6 instead of 4, because the 700 Hz tone aliased onto it. The 700 Hz tone vanished as a separate component, and the 1100 Hz tone appears as a false 100 Hz tone.

**(d)** $X(\omega)$ has impulses at $\pm300$, $\pm700$ and $\pm1100$ Hz, and sampling copies them to every $k(1000) \pm f$:

| Original | Impulse locations in 0–2000 Hz |
| --- | --- |
| $\pm300$ Hz | 300, 700, 1300, 1700 |
| $\pm700$ Hz | 300, 700, 1300, 1700 |
| $\pm1100$ Hz | 100, 900, 1100, 1900 |

The distinct locations are **100, 300, 700, 900, 1100, 1300, 1700 and 1900 Hz**. Only **100 Hz and 300 Hz** lie in the passband $|f| < 500\,\text{Hz}$. The 300 Hz location holds both the original 300 Hz copy and the $k=1$ copy of −700 Hz ($1000-700$). This is the overlap that produced amplitude 6 in part (c).

**(e)** Exact recovery needs $f_s > \mathbf{2200}\,\text{samples/s}$, strictly above the Nyquist rate. With an ideal 500 Hz anti-aliasing filter applied first, only $4\cos(2\pi\cdot300t)$ is sampled. It is below 500 Hz, so it is reconstructed exactly: **$x_r(t) = 4\cos(2\pi\cdot300t)$**. The 700 and 1100 Hz content is lost, but nothing is corrupted by aliasing.

## 9. Systems and filtering

**(a)** The completed table:

| System | Memoryless | Causal | Linear | Time invariant | BIBO stable | Invertible |
| --- | --- | --- | --- | --- | --- | --- |
| S1: $t\,x(t)$ | Y | Y | Y | N | N | N |
| S2: $x[2n]$ | N | N | Y | N | Y | N |
| S3: $x(t)+3$ | Y | Y | N | Y | Y | Y |
| S4: accumulator | N | Y | Y | Y | N | Y |

Justification of each N:

- **S1, time invariant:** shifting the input gives $t\,x(t-t_0)$, but shifting the output gives $(t-t_0)x(t-t_0)$.
- **S1, stable:** $x(t) = 1$ is bounded, but $y(t) = t$ is not.
- **S1, invertible:** $y(0) = 0$ for every input, so $x(0)$ cannot be recovered.
- **S2, memoryless and causal:** $y[1] = x[2]$, a sample at a different, later time.
- **S2, time invariant:** the input $x[n - 1]$ gives $x[2n - 1]$, but $y[n-1] = x[2n-2]$.
- **S2, invertible:** $x[n] = \delta[n-1]$ and $x[n] = 0$ both give $y[n] = 0$, since odd samples are discarded.
- **S3, linear:** a zero input gives $y = 3$, not 0. Also $H[2x] = 2x+3 \ne 2H[x] = 2x+6$.
- **S4, memoryless:** the output uses all past inputs.
- **S4, stable:** $x[n] = u[n]$ gives $y[n] = n+1$ for $n \ge 0$, which is unbounded.

The Y entries hold for these reasons: S3 is stable since $|y| \le M_x+3$, and invertible since $x = y-3$. S4 is invertible since $x[n] = y[n]-y[n-1]$. S2 is stable since $|y[n]| \le M_x$.

**(b)** The impulse response is the accumulated impulse, **$h[n] = u[n]$**. The response splits into two parts:

- **Zero-input** ($x = 0$, $y[-1] = 2$): $y[n] = y[n-1]$, so **$y_{\mathrm{zi}}[n] = 2$** for $n \ge 0$.
- **Zero-state** ($y[-1] = 0$): $y_{\mathrm{zs}}[n] = (x*h)[n] = u[n]-u[n-3]$, which is 1 for $n = 0,1,2$ and 0 for $n \ge 3$.
- **Total:** $y[n] = 2+u[n]-u[n-3] = \mathbf{3,\ 3,\ 3,\ 2,\ 2,\ \ldots}$ for $n = 0,1,2,3,4,\ldots$

Check with the recursion: $y[0] = 2+1 = 3$, $y[1] = 3$, $y[2] = 3$, $y[3] = 3-1 = 2$. A nonzero initial state gives a nonzero output even with zero input.

**(c)** From $e^{-at}u(t) \longleftrightarrow \frac{1}{a+j\omega}$, **$H(\omega) = \frac{1}{2+j\omega}$**.

- DC component: $H(0) = \tfrac12$, so 3 becomes **$\frac32$**.
- 2 rad/s component: $|H(2)| = \frac{1}{\sqrt8} = \frac{1}{2\sqrt2} \approx 0.354$ and $\arg H(2) = -\tan^{-1}(2/2) = -\frac{\pi}{4}$.

$$
y(t)=\frac{3}{2}+\frac{1}{2\sqrt2}\cos\!\left(2t-\frac{\pi}{4}\right)
$$

There is **no 4 rad/s component**: $Y(\omega) = X(\omega)H(\omega)$ is zero wherever $X(\omega)$ is, and an LTI system creates no new frequencies.

**(d)** $h[n] = \delta[n]+\tfrac12\delta[n-2]$ and $H_d(\Omega) = 1+\tfrac12e^{-j2\Omega}$. At $\Omega = 0$, $H_d = \tfrac32$. At $\Omega = \pi/2$, $H_d = 1+\tfrac12e^{-j\pi} = \tfrac12$, which is real, so there is no phase shift. Therefore **$y[n] = 3+\tfrac12\cos(\pi n/2)$**. Direct check: $\cos\!\left(\frac{\pi(n-2)}{2}\right) = -\cos(\pi n/2)$, so $y[n] = 2+\cos(\pi n/2)+\tfrac12(2-\cos(\pi n/2)) = 3+\tfrac12\cos(\pi n/2)$.

**(e)** Reduce each frequency to $[-\pi,\pi]$ first:

- The constant 1 is at $\Omega = 0$, which **passes**.
- $\cos(\pi n/4)$ is at $\pi/4 < \pi/2$, which **passes**.
- $\cos(7\pi n/4) = \cos(-\pi n/4) = \cos(\pi n/4)$: the frequency $7\pi/4$ is equivalent to $-\pi/4$, so it **passes**.
- $(-1)^n = \cos(\pi n)$ is at $\Omega = \pi$, which is **blocked**.

The output is **$y[n] = 1+2\cos(\pi n/4)$**. The trap: $7\pi/4$ looks like a high frequency but is equivalent to $-\pi/4$.
