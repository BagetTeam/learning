import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { getCurrencyRates } from '../api/client';

interface CurrencyContextValue {
  currency: string;
  setCurrency: (c: string) => void;
  formatPrice: (usd: number) => string;
  currencies: string[];
  symbols: Record<string, string>;
}

const CurrencyContext = createContext<CurrencyContextValue>({
  currency: 'USD',
  setCurrency: () => {},
  formatPrice: (usd) => `$${Math.round(usd).toLocaleString()}`,
  currencies: ['USD'],
  symbols: { USD: '$' },
});

export function useCurrency() {
  return useContext(CurrencyContext);
}

export function CurrencyProvider({ children, defaultCurrency }: { children: ReactNode; defaultCurrency?: string }) {
  const [rates, setRates] = useState<Record<string, number>>({ USD: 1 });
  const [symbols, setSymbols] = useState<Record<string, string>>({ USD: '$' });
  const [currency, setCurrencyState] = useState<string>(() => {
    return localStorage.getItem('preferred_currency') || defaultCurrency || 'USD';
  });

  // Update if defaultCurrency changes (from geolocation) and no user preference saved
  useEffect(() => {
    if (defaultCurrency && !localStorage.getItem('preferred_currency')) {
      setCurrencyState(defaultCurrency);
    }
  }, [defaultCurrency]);

  useEffect(() => {
    getCurrencyRates()
      .then((data) => {
        setRates(data.rates);
        setSymbols(data.symbols);
      })
      .catch(() => {});
  }, []);

  function setCurrency(c: string) {
    setCurrencyState(c);
    localStorage.setItem('preferred_currency', c);
  }

  function formatPrice(usd: number): string {
    const rate = rates[currency] ?? 1;
    const symbol = symbols[currency] ?? currency;
    const converted = Math.round(usd * rate);
    // For currencies with large values, use locale formatting
    if (rate > 100) {
      return `${symbol}${converted.toLocaleString()}`;
    }
    return `${symbol}${converted.toLocaleString()}`;
  }

  const currencies = Object.keys(rates).sort();

  return (
    <CurrencyContext.Provider value={{ currency, setCurrency, formatPrice, currencies, symbols }}>
      {children}
    </CurrencyContext.Provider>
  );
}
