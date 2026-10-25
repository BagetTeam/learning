int pell(int n) {
    if (n == 1)
        return 1;
    if (n == 0)
        return 0;

    return 2*pell(n-1) + pell(n-2);
}

// iteratively
int pell_i (int n) {
    if (n == 0)
        return 0;
    
    int prev = 0;
    int cur = 1;
    for (int i = 1; i < n; i++) {
        int tmp = cur;
        cur = 2*cur + prev;
        prev = tmp;
    }
    return cur;
}