# National Bank

## GMM

Note for each gaussian distributions:

- Mean (\(\mu\)): Center of hill
- Variance (\(\sigma^2\)): Spread of hill
- Mixing weight (\(\pi\)): How much this gaussian contributes to overall distribution (totals to 1)

Understanding key terms:
**Probability density**: How concentrated the probability is at location (height of curve)
**Probability**: Chance of X being within a <= X <= b (area under curve)
Total area = 1

Now combine two gaussians, result is just adding probability density of both curves together, which would create 2 peaks.
Then at some x, we check probability density, p(x), at that point, see how much of that is from gaussian 1, how much is from gaussian 2.
_Note: more x is close to peak of gaussian 1, more gaussian 1 will contribute, while gaussian 2 will contribute less._

GMM does not ask which Gaussian a point belongs to before evaluating its density. It calculates the weighted contribution from every Gaussian and adds them together.

Mathematically:

$$
\boxed{p(x)=\sum_{c=1}^{C}\pi_c\mathcal{N}(x\mid\mu_c,\Sigma_c)}
$$

(add all prob densities of each gaussians)

Seems complicated but with 2, it looks like
\(p(x) = 0.5\,\mathcal N(x|-2,1)+0.5\,\mathcal N(x|2,1)\) (\(\mu\)=2, \(\sigma\)=1)

New term:
**Responsibilty**: Probability that a certain point belongs to each component

**Likelihood (L)**: Say we have 3 points, each have its own density $p(x_i)$. Multiply the 3 densities, that is L.
$L = p(x_1) * p(x_2) * p(x_3)$
For independent data points, the likelihood is:

$$
L(\theta;X)=\prod_{i=1}^{n}p(x_i\mid\theta)
$$

\(\theta\): Model parameters (mean, variance, mixing weight)
_Note: Likelihood is not probability that model is correct, but a joint density of the observed data as a function of the model's params._

**Log-likelihood**: Multiplying all densities can get very small, is not very properly representable for computer. So use $\ln$ instead.

$$
\ln L=\ln\left(\prod_{i=1}^{n}p(x_i)\right)
$$

$$
\boxed{\ln L=\sum_{i=1}^{n}\ln p(x_i)}
$$

With logs, we can add instead, and won't affect result.
**Goal**: Maximize log-likelihood

Linking to BIC: More clusters = log likelihood increase (adding more gaussions make it flexible based on data, and can just map the data entirely)

Explaining prob density:

> If from 1.5 <= X <= 1.6, our density is high, while 1.1 <= X <= 1.2 is low, for a same interval, the probability of x appearing in first interval is much higher. If we had an infinite number of points, its much more dense, and so chance of a point being within that dense region is higher.

## Kmean

## BIC

Issue is, the more I add clusters, the more compact and 'good' the clustering is gonna look, since the data will be more fitted together. However, our goal is not to have an infinite amount of cluters, that would be useless as we could just have one cluster per point, defeats the purpose of clustering points together.
So how do we evaluate if the amount of clusters is the right amount, if we are catching the right amount of behaviors. This is what BIC is for, it is for determining the ideal number of clusters we would want for our dataset. Formula look like this:

$$\mathrm{BIC} = -2\ln(\hat{L}) + k\ln(n)$$

$\hat{L}$: Maximized likelihood of the fitted model (how well it explains the data)
n: Number of data point
k: Number of free parameters in the model (depends on \# features, \# clusters, complexity of model (covarience matrices structure))

ex. Using GMM, with diagonal covariance
C: Number of clusters
d: Number of features
We would see something like:
$$k = (C - 1) + C \cdot d + C \cdot d$$

Our goal is changing C, and finding best BIC score (minimum).

What does 'explain the data' mean:
**GMM:** points fall within probability cloud, not on edges. This means on the hill of the gaussian distribution, we check where the point is located, and check its height on the distribution and add all the ehgihts together and maximize this.
**KMean:** Dont actually use BIC, but **_Silhouette Score_**. Go to

##### Note: AIC

AIC unlike BIC doesn't use sample size. Has weaker penalty on complexity ($2k$ instead of $k\ln(n)$).
Used for predicting or approximate future data (minimize information loss). Will our new data point fit within the clusters we have.
**Goal:** If you collect a brand-new batch of data tomorrow from the exact same system, how well will your current cluster model explain or map those new points?

#### Conclusion

Tool to penalize complexity and prevent overfitting.
BIC -> For estimating amount of clusters, avoiding splitting real clusters into artificial ones

## Silhouette Score

It measures how similar a data point is to other points in its cluster compared to neighboring clusters.

Formula:
For a single data point i:
$$s(i)=\frac{b(i)-a(i)}{\max (a(i),b(i))}$$
• a(i): The mean intra-cluster distance (average distance from point i to all other points in the same cluster).
• b(i): The mean nearest-cluster distance (average distance from point i to all points in the closest cluster that i is not a part of)

And get average of all points

What score means:

- Close to 1 -> Excellent, points are dense
- Around 0 -> Overlapping clusters, points sit in boundary between both
- Close to -1 -> Point is simply in wrong cluster, and close to neighboring one

This measures both compactness and seperation unlike the **_Elbow Method_**, which is only for compactness
