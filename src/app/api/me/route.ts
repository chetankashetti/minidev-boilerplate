import { NextRequest, NextResponse } from "next/server";
import { createClient, Errors } from "@farcaster/quick-auth";
import { FarcasterUser, FarcasterApiResponse, ApiError } from "@/types";

const client = createClient();

// Resolve information about the authenticated Farcaster user
async function resolveUser(fid: number): Promise<FarcasterUser> {
  try {
    const primaryAddress = await (async () => {
      const res = await fetch(
        `https://api.farcaster.xyz/fc/primary-address?fid=${fid}&protocol=ethereum`
      );

      if (res.ok) {
        const data = await res.json();
        const { result } = data as FarcasterApiResponse;
        return result.address.address;
      }
      return null;
    })();

    return {
      fid,
      primaryAddress: primaryAddress || undefined,
    };
  } catch (error) {
    console.error("Error resolving user:", error);
    return {
      fid,
      primaryAddress: undefined,
    };
  }
}

export async function GET(request: NextRequest) {
  const authorization = request.headers.get("Authorization");

  if (!authorization || !authorization.startsWith("Bearer ")) {
    return NextResponse.json<ApiError>(
      { error: "Missing or invalid authorization header" },
      { status: 401 }
    );
  }

  try {
    const token = authorization.split(" ")[1];
    // For localtunnel testing, we need to use the exact domain from NEXTAUTH_URL
    const fullDomain = process.env.NEXTAUTH_URL!;
    // Get the exact domain from the request URL
    // Extract just the hostname from the full URL for JWT verification
    const domain = new URL(fullDomain).hostname;

    console.log("Verifying token for domain:", domain);

    const payload = await client.verifyJwt({
      token,
      domain,
    });

    const user = await resolveUser(payload.sub);

    return NextResponse.json<FarcasterUser>(user);
  } catch (error: unknown) {
    if (error instanceof Errors.InvalidTokenError) {
      console.info("Invalid token:", error.message);
      return NextResponse.json<ApiError>(
        { error: "Invalid token" },
        { status: 401 }
      );
    }

    console.error("Quick auth error:", error);
    return NextResponse.json<ApiError>(
      { error: "Authentication failed" },
      { status: 500 }
    );
  }
}
