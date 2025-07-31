"use client";

import { useEffect, useState } from "react";
import { useAccount } from "wagmi";
import { sdk } from "@farcaster/miniapp-sdk";

/**
 * Unified user hook that works for both Farcaster miniapp and regular browser environments
 *
 * Usage:
 * ```tsx
 * import { useUser } from '@/hooks';
 *
 * function MyComponent() {
 *   const { address, username, isMiniApp, isLoading } = useUser();
 *
 *   if (isLoading) return <div>Loading...</div>;
 *
 *   if (isMiniApp) {
 *     return <div>Hello {username}!</div>;
 *   } else {
 *     return <div>Wallet: {address}</div>;
 *   }
 * }
 * ```
 */

interface FarcasterUser {
  fid: number;
  primaryAddress?: string;
  displayName?: string;
  username?: string;
  pfpUrl?: string;
  location?: {
    placeId?: string;
    description?: string;
  } | null;
}

export interface UserData {
  // Common fields
  address?: string;

  // Farcaster-specific fields (only available in miniapp)
  fid?: number;
  username?: string;
  displayName?: string;
  pfpUrl?: string;
  location?: {
    placeId?: string;
    description?: string;
  } | null;

  // Meta information
  isMiniApp: boolean;
  isLoading: boolean;
  error?: string;
}

export function useUser(): UserData {
  const [userData, setUserData] = useState<UserData>({
    isMiniApp: false,
    isLoading: true,
  });

  // Wagmi hook for wallet connection (used in regular browser)
  const { address: walletAddress, isConnected } = useAccount();

  useEffect(() => {
    let isMounted = true;

    async function initializeUser() {
      try {
        setUserData((prev) => ({ ...prev, isLoading: true, error: undefined }));

        // Check if running in a Farcaster Mini App
        const isMiniApp = await sdk.isInMiniApp();

        if (isMiniApp) {
          // Farcaster miniapp flow
          try {
            // Get user context from SDK
            const userContext = await sdk.context;
            const farcasterUser: FarcasterUser | null = userContext.user;

            if (farcasterUser && isMounted) {
              // Try to fetch additional user data from API
              let apiUserData = null;
              try {
                const res = await sdk.quickAuth.fetch("/api/me");
                if (res.ok) {
                  apiUserData = await res.json();
                }
              } catch (apiError) {
                console.warn(
                  "Failed to fetch additional user data from API:",
                  apiError
                );
              }

              setUserData({
                address:
                  farcasterUser.primaryAddress || apiUserData?.primaryAddress,
                fid: farcasterUser.fid,
                username: farcasterUser.username,
                displayName: farcasterUser.displayName,
                pfpUrl: farcasterUser.pfpUrl,
                location: farcasterUser.location,
                isMiniApp: true,
                isLoading: false,
              });

              // Signal that the app is ready
              sdk.actions.ready();
            } else if (isMounted) {
              setUserData({
                isMiniApp: true,
                isLoading: false,
                error: "Unable to get user data from Farcaster",
              });
            }
          } catch (farcasterError) {
            console.error("Farcaster authentication failed:", farcasterError);
            if (isMounted) {
              setUserData({
                isMiniApp: true,
                isLoading: false,
                error: "Farcaster authentication failed",
              });
            }
          }
        } else {
          // Regular browser flow - just use wallet connection
          if (isMounted) {
            setUserData({
              address: isConnected ? walletAddress : undefined,
              isMiniApp: false,
              isLoading: false,
            });
          }
        }
      } catch (error) {
        console.error("Error initializing user:", error);
        if (isMounted) {
          setUserData({
            isMiniApp: false,
            isLoading: false,
            error: "Failed to initialize user data",
          });
        }
      }
    }

    initializeUser();

    return () => {
      isMounted = false;
    };
  }, [walletAddress, isConnected]);

  return userData;
}
