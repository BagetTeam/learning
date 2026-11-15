# ECSE 316 Practice Midterm 2 (Lectures 6–9)

Nov 15, 2026 · @Ewen Gueguen

This practice exam covers the Fourier transform (Lecture 6), discrete-time signals and sampling (Lecture 7), the transport layer (Lecture 8) and systems (Lecture 9). It follows the style of Midterm 1 but is longer on purpose: answer all nine questions, closed book, with the formula sheet at the end. Suggested time: about 2.5 hours. Full worked solutions are in the Answer key tab.

| Question | Topic | Marks |
| --- | --- | --- |
| 1 | Short answers | 24 |
| 2 | Stop-and-wait, pipelining and window sizing | 12 |
| 3 | Go-Back-N and Selective Repeat | 10 |
| 4 | TCP sequence numbers, timers and flow control | 14 |
| 5 | TCP congestion control | 12 |
| 6 | Fourier transform properties | 14 |
| 7 | Discrete-time signals and the DTFT | 16 |
| 8 | Sampling and aliasing | 14 |
| 9 | Systems and filtering | 16 |
|  | Total | 132 |

## 1. Short answers (24 marks)

Each part is worth 2 marks. Give the quantities, expressions or explanations requested.

**(a)** A host has one UDP socket bound to port 5000 and a TCP server listening on port 80. Two UDP segments arrive with destination port 5000, one from (IP A, port 9157) and one from (IP C, port 9157). Two TCP segments arrive on established connections with destination port 80, from the same two (IP, port) pairs. How many distinct sockets receive the two UDP segments? How many receive the two TCP segments? State what each protocol uses to demultiplex.

**(b)** Compute the Internet checksum (16-bit one's-complement sum, then complement) of the three 16-bit words below. Show the wraparound step.

```
0110 0110 0110 0000
0101 0101 0101 0101
1000 1111 0000 1100
```

**(c)** The receiver recomputes the checksum and it matches the checksum field. Can it conclude that no bits were flipped? Answer yes or no and describe a specific two-bit error the checksum cannot detect.

**(d)** Distinguish flow control from congestion control: state the problem each solves and name the TCP quantity that implements each (one is a header field, one is a sender variable).

**(e)** rdt2.1 and rdt3.0 use only the sequence numbers 0 and 1. Explain why one bit is enough, and what the receiver does with a packet whose sequence number is not the one it expects.

**(f)** Give two reasons an application such as DNS or real-time streaming might use UDP rather than TCP. If such an application needs reliability, where must it be added?

**(g)** Evaluate both sums.

$$
\begin{gathered}
S_1=\sum_{n=-\infty}^{\infty}(n^2+1)\,\delta[2-n] \\
S_2=\sum_{k=-\infty}^{3}\delta[k+1]
\end{gathered}
$$

**(h)** Classify each sequence as an energy signal, a power signal or neither, and give its energy and average power: $x_1[n] = (0.5)^n u[n]$ and $x_2[n] = 3e^{j(\pi/5)n}$.

**(i)** For $x_3[n] = e^{j(11\pi/4)n}$ and $x_4[n] = \cos(9\pi n/5)$, give an equivalent frequency in $[-\pi,\pi)$ and the fundamental period of each sequence.

**(j)** A 3 kHz cosine is sampled and then reconstructed with an ideal lowpass filter whose cutoff is half the sampling rate. What frequency is reconstructed if $f_s = 8\,\text{kHz}$? If $f_s = 5\,\text{kHz}$?

**(k)** The input $x(t) = \cos(4t)$ is applied to (i) an LTI system and (ii) the squarer $y(t) = x^2(t)$. For each, can the output contain a component at 8 rad/s? Justify briefly.

**(l)** Find the Fourier transform of $x(t) = e^{-3(t-2)}u(t-2)$. Evaluate its magnitude and phase at $\omega = 3\,\text{rad/s}$.

## 2. Stop-and-wait, pipelining and window sizing (12 marks)

Host A sends to host B over a single link of rate $R = 100\,\text{Mbit/s}$ with one-way propagation delay 10 ms. Every data packet is $L = 1{,}500\,\text{bytes}$. Ignore headers, processing, queueing and the transmission time of ACKs; ACKs are never lost. Use decimal units ($1\,\text{Mbit} = 10^6\,\text{bits}$) and give times in ms.

**(a) [2 marks]** Calculate the transmission delay $L/R$ and the time from when A starts sending a packet until its ACK arrives back at A.

**(b) [2 marks]** A uses stop-and-wait (rdt3.0). Calculate the sender utilization and the resulting throughput in kbit/s.

**(c) [3 marks]** A now pipelines with a window of N packets. Write the utilization as a function of N (valid while the window is not large enough to keep the link busy). Find the smallest N giving utilization of at least 90%, and the resulting throughput in Mbit/s. What is the smallest N that keeps the link continuously busy?

**(d) [3 marks]** Using the N from part (c) for 90%, find the minimum number of sequence-number bits k needed for (i) Go-Back-N and (ii) Selective Repeat. Explain, with reference to the Selective Repeat "dilemma" from lecture, why Selective Repeat needs more.

**(e) [2 marks]** The link is upgraded to 1 Gbit/s while N stays at the value from part (c). Recalculate the utilization and throughput. What now limits the throughput, and what does this suggest about the relationship between window size, RTT and throughput?

## 3. Go-Back-N and Selective Repeat (10 marks)

A sender has seven packets, pkt0 to pkt6, to deliver. The window size is $N = 4$ and sequence numbers run from 0 to 7. The sender transmits whenever its window allows. The first transmission of pkt2 is lost; no other data packet and no ACK is lost. As in the lecture examples, assume the timer for pkt2 expires only after the sender has sent every packet its window allows and has received every ACK in flight. Retransmissions are not lost.

**(a) [4 marks]** Go-Back-N with cumulative ACKs and a receiver that discards out-of-order packets. List, in order, each packet the receiver receives before the timeout, what it does with it and which ACK it sends. State which packets the sender transmits when the timer expires, and when pkt6 is first sent. Count the total number of data-packet transmissions needed to deliver all seven packets.

**(b) [4 marks]** Repeat part (a) for Selective Repeat with individual ACKs and receiver buffering. Also give the sender's window (the four sequence numbers it covers) just before the timeout, and explain why pkt6 cannot be sent then.

**(c) [2 marks]** In Selective Repeat, the receiver gets a second copy of pkt1 after its window has already moved past 1 (because ack1 was delayed and the sender timed out). What must the receiver do, and what would go wrong if it simply ignored the packet?

## 4. TCP sequence numbers, timers and flow control (14 marks)

**(a) [4 marks]** Host B has received every byte from host A up to and including byte 499. A then sends three segments back to back: Seg1 carries 80 bytes and has sequence number 500, Seg2 carries 120 bytes and Seg3 carries 50 bytes.

1. Give the sequence numbers of Seg2 and Seg3.
2. Seg2 is lost. Seg1 and Seg3 arrive, and B buffers out-of-order data. Give the acknowledgement number in the ACK that B sends for Seg1 and for Seg3.
3. A retransmits Seg2 and it arrives. Give the acknowledgement number of B's next ACK.
4. In a different run, nothing is lost, but the ACK for Seg1 is lost while the ACK for Seg2 arrives before Seg1's timer expires. Does A retransmit Seg1? Explain.

**(b) [2 marks]** How many ACKs carrying the same acknowledgement number must A receive in total before TCP fast retransmit is triggered? Which segment is resent, and why is waiting for the timeout avoided?

**(c) [4 marks]** A TCP sender currently has $\mathrm{EstimatedRTT} = 100\,\text{ms}$ and $\mathrm{DevRTT} = 10\,\text{ms}$, with $\alpha = 0.125$ and $\beta = 0.25$. Two new samples arrive in order: $\mathrm{SampleRTT} = 140\,\text{ms}$, then $\mathrm{SampleRTT} = 90\,\text{ms}$. After each sample, update EstimatedRTT first, then DevRTT (using the updated EstimatedRTT), then TimeoutInterval. Write each update equation before evaluating it. Finally, explain why TCP does not take a SampleRTT from a retransmitted segment.

**(d) [2 marks]** A client chooses initial sequence number 3000 and the server chooses 9000. For each of the three handshake segments, give the flags set (SYN, ACK), the sequence number and, where present, the acknowledgement number. What sequence number does the first byte of client data carry?

**(e) [2 marks]** B's RcvBuffer is 8,192 bytes and holds 5,000 bytes not yet read by the application. What rwnd does B advertise? A currently has $\mathrm{LastByteSent} - \mathrm{LastByteAcked} = 2{,}000\,\text{bytes}$. How many more bytes may A send before receiving a new ACK?

## 5. TCP congestion control (12 marks)

A TCP Reno sender measures cwnd in MSS at the start of each transmission round (one RTT). Initially $\mathrm{cwnd} = 1\,\text{MSS}$ and $\mathrm{ssthresh} = 16\,\text{MSS}$. Use these rules:

- **Slow start ($\mathrm{cwnd} < \mathrm{ssthresh}$):** cwnd doubles each round, but if doubling would exceed ssthresh, cwnd is set equal to ssthresh.
- **Congestion avoidance ($\mathrm{cwnd} \ge \mathrm{ssthresh}$):** cwnd increases by 1 MSS per round.
- **Triple duplicate ACK:** $\mathrm{ssthresh} = \frac{\mathrm{cwnd}}{2}$ and $\mathrm{cwnd} = \mathrm{ssthresh}$ (the window is cut in half).
- **Timeout:** $\mathrm{ssthresh} = \frac{\mathrm{cwnd}}{2}$ and $\mathrm{cwnd} = 1\,\text{MSS}$; slow start resumes.

A triple duplicate ACK is detected at the end of round 9. A timeout occurs at the end of round 12. No other losses occur.

**(a) [4 marks]** Give cwnd for rounds 1 to 18 in a table.

**(b) [2 marks]** Identify the rounds in slow start and the rounds in congestion avoidance. What signals the switch from slow start to congestion avoidance?

**(c) [2 marks]** Give the value of ssthresh during rounds 6, 11 and 17.

**(d) [2 marks]** Suppose instead the sender is TCP Tahoe, which reacts to the loss at the end of round 9 as if it were a timeout. Ignore the round-12 timeout for this part. Give cwnd and ssthresh for rounds 10 to 14.

**(e) [2 marks]** With $\mathrm{MSS} = 1{,}460\,\text{bytes}$ and $\mathrm{RTT} = 40\,\text{ms}$, estimate the sending rate in round 9 in Mbit/s using $\text{rate} \approx \frac{\mathrm{cwnd}}{\mathrm{RTT}}$. How many segments in total are sent in rounds 1 to 5?

## 6. Fourier transform properties (14 marks)

Let $x(t) = e^{-a|t|}$ with $a > 0$. Use the transform definition on the formula sheet.

**(a) [4 marks]** Derive $X(\omega)$ directly from the analysis integral by splitting it at $t = 0$. Explain why $X(\omega)$ is real and even, and state its value at $\omega = 0$ with an interpretation in terms of $x(t)$.

For the rest of this question take $a = 2$, so that $x(t) = e^{-2|t|}$.

**(b) [4 marks]** Using transform properties only (no new integrals), find the Fourier transform of each signal. Name the property used each time.

1. $x(t-3)$
2. $x(2t)$
3. $x(t)\cos(10t)$
4. $(x * x)(t)$

For signal 1, state how its magnitude spectrum compares with $|X(\omega)|$. For signal 2, check your result by writing $x(2t)$ as a two-sided exponential and using part (a).

**(c) [2 marks]** Does $x(t)$ have a finite strict bandwidth? Find the positive frequency at which $|X(\omega)|$ falls to half of $X(0)$.

**(d) [4 marks]** Consider the periodic signal

$$
s(t) = 2 + 4\cos(5t) - 6\sin(10t).
$$

State its fundamental angular frequency, read its nonzero Fourier-series coefficients $D_n$ by inspection (Euler's identity), and write its Fourier transform $S(\omega)$ as a sum of weighted impulses. Give every impulse location and weight.

## 7. Discrete-time signals and the DTFT (16 marks)

Let

$$
\begin{gathered}
x[n] = 2\delta[n] + \delta[n-1] - \delta[n-2] + 3\delta[n-3] \\
h[n] = \delta[n] - \delta[n-1].
\end{gathered}
$$

**(a) [2 marks]** Compute the energy and average power of $x[n]$. Is it an energy signal or a power signal?

**(b) [3 marks]** List the nonzero samples (index and value) of each sequence:

1. $x[n + 1]$
2. $x[2 - n]$
3. the decimated sequence $x[2n]$
4. the expanded sequence $z[n]$ obtained by expanding $x[n]$ by a factor of $L = 2$

Which of these operations can lose information?

**(c) [3 marks]** Compute $y[n] = (x * h)[n]$ for all n, showing the sum you evaluate. Give a one-line interpretation of what this $h[n]$ does to its input.

**(d) [3 marks]** Find $X_d(\Omega)$, $H_d(\Omega)$ and $Y_d(\Omega) = X_d(\Omega)H_d(\Omega)$. Check that the coefficients of $Y_d(\Omega)$ agree with part (c). Evaluate $X_d(0)$, $X_d(\pi)$ and $Y_d(0)$, and explain why $Y_d(0)$ has the value it does. Show that $|H_d(\Omega)| = 2|\sin(\Omega/2)|$ and say what kind of filter $h[n]$ is.

**(e) [3 marks]** Let $g[n] = (0.5)^n u[n-2]$. Using the transform of $a^n u[n]$ and the time-shift property, find $G_d(\Omega)$. Check your answer by evaluating $G_d(0)$ and comparing it with the sum of the samples of $g[n]$.

**(f) [2 marks]** Determine whether each sequence is periodic and, if so, give its fundamental period: $x_1[n] = e^{j(\pi/6)n}$, $x_2[n] = e^{j(4\pi/9)n}$, $x_3[n] = x_1[n] + x_2[n]$, $x_4[n] = \cos(n/2)$.

## 8. Sampling and aliasing (14 marks)

The signal

$$
x(t) = 4\cos(2\pi\cdot 300\,t) + 2\cos(2\pi\cdot 700\,t) + \cos(2\pi\cdot 1100\,t)
$$

(t in seconds) is sampled at $f_s = 1000\,\text{samples/s}$ to give $x[n] = x(nT_s)$.

**(a) [2 marks]** State the bandlimit B of $x(t)$ in rad/s and its Nyquist rate in samples/s. State the Nyquist frequency of this sampler in Hz. Will aliasing occur?

**(b) [4 marks]** Write $x[n]$ as a sum of cosines whose discrete-time frequencies lie in $[0,\pi]$ rad/sample. Show, for each term, the frequency $\Omega = \omega T_s$ and how you reduce it using the $2\pi$ periodicity of frequency and the evenness of cosine.

**(c) [3 marks]** The samples are passed through the ideal reconstruction system from lecture: an impulse-train model followed by a lowpass filter with gain $T_s$ and cutoff $\pi/T_s$ rad/s. State the cutoff in Hz and write the reconstructed signal $x_r(t)$. Which components of $x(t)$ were recovered correctly?

**(d) [3 marks]** The sampled spectrum is

$$
\tilde X(\omega) = \frac{1}{T_s}\sum_{k=-\infty}^{\infty} X(\omega - k\omega_s).
$$

List every frequency in hertz in the range 0 to 2000 Hz at which this spectrum has an impulse. Identify which of them lie inside the reconstruction filter's passband and confirm that this agrees with part (c).

**(e) [2 marks]** What is the smallest sampling rate above which $x(t)$ can be recovered exactly? Alternatively, if an ideal anti-aliasing lowpass filter with cutoff 500 Hz is applied before sampling at 1000 samples/s, what signal is reconstructed?

## 9. Systems and filtering (16 marks)

**(a) [6 marks]** Classify each system. Copy the table, enter Y or N in every cell, and justify each N with a counterexample or a one-line reason.

- S1: $y(t) = t\,x(t)$
- S2: $y[n] = x[2n]$
- S3: $y(t) = x(t) + 3$
- S4: $y[n] = \sum_{k=-\infty}^{n}x[k]$ (the accumulator)

| System | Memoryless | Causal | Linear | Time invariant | BIBO stable | Invertible |
| --- | --- | --- | --- | --- | --- | --- |
| S1 |  |  |  |  |  |  |
| S2 |  |  |  |  |  |  |
| S3 |  |  |  |  |  |  |
| S4 |  |  |  |  |  |  |

**(b) [3 marks]** The accumulator S4 can be written as $y[n] = y[n-1] + x[n]$. Find its impulse response $h[n]$. Suppose its initial state is $y[-1] = 2$ and the input $x[n] = \delta[n] - \delta[n-3]$ is applied for $n \ge 0$. Find the zero-input response, the zero-state response and the total response for $n \ge 0$.

**(c) [3 marks]** A continuous-time LTI system has impulse response $h(t) = e^{-2t}u(t)$. Find its frequency response $H(\omega)$. The input $x(t) = 3 + \cos(2t)$ is applied. Find the output $y(t)$, giving the gain and phase shift applied to each component. Can $y(t)$ contain a component at 4 rad/s?

**(d) [2 marks]** The discrete-time echo $y[n] = x[n] + \tfrac12 x[n-2]$ has input $x[n] = 2 + \cos(\pi n/2)$. Find $h[n]$ and $H_d(\Omega)$, then the output $y[n]$. Verify your answer by substituting directly into the echo equation.

**(e) [2 marks]** An ideal discrete-time lowpass filter has $H_d(\Omega) = 1$ for $|\Omega| \le \pi/2$ and 0 for $\pi/2 < |\Omega| \le \pi$, repeating every $2\pi$. Find the output for the input

$$
x[n] = 1 + \cos\!\left(\frac{\pi n}{4}\right) + \cos\!\left(\frac{7\pi n}{4}\right) + (-1)^n.
$$

## Formula sheet

Like the Midterm 1 sheet, this covers signals only; transport-layer relations (utilization, EWMA, timeout) are expected from memory. Conventions: $\operatorname{sinc}(v) = \frac{\sin v}{v}$ with $\operatorname{sinc}(0) = 1$; $u(t)$ and $u[n]$ equal 1 at 0.

**Continuous-time Fourier transform**

$$
\begin{gathered}
X(\omega)=\int_{-\infty}^{\infty}x(t)e^{-j\omega t}\,dt \\
x(t)=\frac{1}{2\pi}\int_{-\infty}^{\infty}X(\omega)e^{j\omega t}\,d\omega
\end{gathered}
$$

| Property | Time domain | Frequency domain |
| --- | --- | --- |
| Linearity | $\alpha x(t) + \beta z(t)$ | $\alpha X(\omega) + \beta Z(\omega)$ |
| Time shift | $x(t-t_0)$ | $e^{-j\omega t_0}X(\omega)$ |
| Time scaling, $b \ne 0$ | $x(bt)$ | $\frac{1}{\lvert b\rvert}X(\omega/b)$ |
| Frequency shift | $x(t)e^{j\omega_c t}$ | $X(\omega-\omega_c)$ |
| Cosine modulation | $x(t)\cos(\omega_c t)$ | $\frac12[X(\omega-\omega_c)+X(\omega+\omega_c)]$ |
| Convolution | $(x*z)(t)$ | $X(\omega)Z(\omega)$ |
| Multiplication | $x(t)z(t)$ | $\frac{1}{2\pi}(X*Z)(\omega)$ |

| Signal | Transform |
| --- | --- |
| $\delta(t)$ | $1$ |
| $1$ | $2\pi\delta(\omega)$ |
| $e^{j\omega_0 t}$ | $2\pi\delta(\omega-\omega_0)$ |
| $\cos(\omega_c t)$ | $\pi[\delta(\omega-\omega_c)+\delta(\omega+\omega_c)]$ |
| $e^{-at}u(t)$, $a > 0$ | $\frac{1}{a+j\omega}$ |
| Rectangular pulse of width $T$ centred at 0 | $T\operatorname{sinc}(\omega T/2)$ |
| Periodic signal $\sum_{n=-\infty}^{\infty}D_n e^{jn\omega_0 t}$ | $2\pi\sum_{n=-\infty}^{\infty}D_n\delta(\omega-n\omega_0)$ |

**Discrete time**

$$
\begin{gathered}
E_x=\sum_{n=-\infty}^{\infty}|x[n]|^2 \\
P_x=\lim_{N\to\infty}\frac{1}{2N+1}\sum_{n=-N}^{N}|x[n]|^2 \\
(x*h)[n]=\sum_{k=-\infty}^{\infty}x[k]h[n-k]
\end{gathered}
$$

$$
\begin{gathered}
X_d(\Omega)=\sum_{n=-\infty}^{\infty}x[n]e^{-j\Omega n} \\
x[n]=\frac{1}{2\pi}\int_{-\pi}^{\pi}X_d(\Omega)e^{j\Omega n}\,d\Omega \\
\sum_{n=0}^{\infty}r^n=\frac{1}{1-r},\ |r|<1
\end{gathered}
$$

| DTFT property or pair | Time domain | Frequency domain |
| --- | --- | --- |
| Shift, integer $n_0$ | $x[n-n_0]$ | $e^{-j\Omega n_0}X_d(\Omega)$ |
| Reversal | $x[-n]$ | $X_d(-\Omega)$ |
| Convolution | $(x*h)[n]$ | $X_d(\Omega)H_d(\Omega)$ |
| Geometric, $\lvert a\rvert < 1$ | $a^n u[n]$ | $\frac{1}{1-ae^{-j\Omega}}$ |

**Sampling**

$$
\begin{gathered}
x[n]=x(nT_s) \\
\omega_s=\frac{2\pi}{T_s} \\
\Omega=\omega T_s \\
\tilde X(\omega)=\frac{1}{T_s}\sum_{k}X(\omega-k\omega_s) \\
x(t)=\sum_{n}x[n]\,\mathrm{sinc}\!\left(\pi\frac{t-nT_s}{T_s}\right)
\end{gathered}
$$
