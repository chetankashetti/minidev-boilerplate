export interface FarcasterUser {
  fid: number;
  primaryAddress?: string;
}

export interface QuickAuthResponse {
  fid: number;
  primaryAddress?: string;
}

export interface FarcasterApiResponse {
  result: {
    address: {
      fid: number;
      protocol: "ethereum" | "solana";
      address: string;
    };
  };
}

export interface ContractConfig {
  address: string;
  abi: unknown[];
  chainId: number;
}

export interface MiniappConfig {
  name: string;
  description: string;
  iconUrl: string;
  homeUrl: string;
  primaryCategory: string;
  tags: string[];
}

export interface ApiError {
  error: string;
}
