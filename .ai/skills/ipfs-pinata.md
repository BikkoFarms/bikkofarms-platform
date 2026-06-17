# Skill Manual: IPFS & Pinata (Harvest Token Metadata)

Guidelines for storing, structuring, and retrieving harvest token metadata on IPFS via Pinata for BikkoChain.

---

## 🎯 Purpose

Each minted `HarvestToken` (ERC-1155) on Lisk references an IPFS URI containing the full harvest metadata JSON — GPS coordinates, crop type, estimated yield, EPCIS supply chain events, and EUDR compliance proof. Pinata is used as the IPFS pinning service to ensure permanence.

---

## 🔑 Key Facts

- **Service:** Pinata (`https://api.pinata.cloud`)
- **SDK:** `@pinata/sdk` or raw `axios` calls to Pinata API
- **Gateway:** `https://gateway.pinata.cloud/ipfs/{CID}` for reading metadata
- **Token standard:** ERC-1155 — `uri(tokenId)` returns the IPFS URL
- **IPFS CID is immutable** — once uploaded, content cannot be changed. Update = new upload + new token.

---

## 📋 Metadata JSON Schema (EPCIS + EUDR)

Every harvest token's metadata must conform exactly to this schema:

```json
{
  "name": "Cocoa Harvest — Batch #0042",
  "description": "Tokenized future harvest, Tepa district, Ghana",
  "image": "ipfs://QmImageCIDHere...",
  "properties": {
    "farmerId": "0xfarmerWalletAddress...",
    "gpsCoordinates": { "lat": 6.2345, "lng": -2.3456 },
    "cropType": "cocoa",
    "estimatedKg": 500,
    "harvestSeason": "2026-Q3",
    "organicCertified": true,
    "deforestationFreeProof": "https://eudr-registry.bikkofarms.com/proof/0042",
    "epcisEvents": [
      {
        "eventType": "ObjectEvent",
        "action": "ADD",
        "bizStep": "urn:epcglobal:cbv:bizstep:planting",
        "eventTime": "2026-01-15T00:00:00Z",
        "location": "Tepa, Ahafo Region, Ghana"
      },
      {
        "eventType": "ObjectEvent",
        "action": "ADD",
        "bizStep": "urn:epcglobal:cbv:bizstep:harvest_forecast",
        "eventTime": "2026-06-01T00:00:00Z",
        "expectedYieldKg": 500
      }
    ]
  }
}
```

---

## 📐 Code Conventions

### PinataService.ts

```typescript
// services/PinataService.ts
import axios from 'axios';
import logger from '../config/logger';

export interface HarvestMetadata {
  name: string;
  description: string;
  image: string;
  properties: {
    farmerId: string;
    gpsCoordinates: { lat: number; lng: number };
    cropType: 'cocoa' | 'coffee';
    estimatedKg: number;
    harvestSeason: string;       // e.g. "2026-Q3"
    organicCertified: boolean;
    deforestationFreeProof: string;
    epcisEvents: EpcisEvent[];
  };
}

export interface EpcisEvent {
  eventType: 'ObjectEvent';
  action: 'ADD' | 'DELETE' | 'OBSERVE';
  bizStep: string;               // urn:epcglobal:cbv:bizstep:...
  eventTime: string;             // ISO 8601
  location?: string;
  expectedYieldKg?: number;
}

export class PinataService {
  private readonly baseUrl = 'https://api.pinata.cloud';
  private readonly apiKey = process.env.PINATA_API_KEY!;
  private readonly secretKey = process.env.PINATA_SECRET_API_KEY!;

  async pinMetadata(metadata: HarvestMetadata): Promise<string> {
    try {
      const response = await axios.post(
        `${this.baseUrl}/pinning/pinJSONToIPFS`,
        {
          pinataContent: metadata,
          pinataMetadata: {
            name: metadata.name,
            keyvalues: {
              farmerId: metadata.properties.farmerId,
              cropType: metadata.properties.cropType,
            },
          },
        },
        {
          headers: {
            pinata_api_key: this.apiKey,
            pinata_secret_api_key: this.secretKey,
            'Content-Type': 'application/json',
          },
          timeout: 15_000,
        }
      );

      const cid: string = response.data.IpfsHash;
      logger.info({ cid, farmerId: metadata.properties.farmerId }, 'Metadata pinned to IPFS');
      return cid;
    } catch (error) {
      logger.error({ error }, 'Failed to pin metadata to IPFS');
      throw error;
    }
  }

  buildIpfsUri(cid: string): string {
    return `ipfs://${cid}`;
  }

  buildGatewayUrl(cid: string): string {
    return `${process.env.PINATA_GATEWAY_URL}/ipfs/${cid}`;
  }
}
```

### TokenService.ts (Minting Flow)

```typescript
// services/TokenService.ts — tokenization flow
async mintHarvestToken(farmerId: string, params: MintParams): Promise<{ tokenId: number; cid: string; txHash: string }> {
  // 1. Build EPCIS metadata
  const metadata: HarvestMetadata = {
    name: `${params.cropType} Harvest — Batch #${params.batchNumber}`,
    description: `Tokenized future harvest, ${params.village}, Ghana`,
    image: 'ipfs://QmDefaultCropImageCID', // Pre-uploaded crop image
    properties: {
      farmerId: params.walletAddress,
      gpsCoordinates: { lat: params.gpsLat, lng: params.gpsLng },
      cropType: params.cropType,
      estimatedKg: params.estimatedKg,
      harvestSeason: params.harvestSeason,
      organicCertified: params.organicCertified,
      deforestationFreeProof: `https://eudr-registry.bikkofarms.com/proof/${params.batchNumber}`,
      epcisEvents: [
        {
          eventType: 'ObjectEvent',
          action: 'ADD',
          bizStep: 'urn:epcglobal:cbv:bizstep:planting',
          eventTime: new Date().toISOString(),
          location: `${params.village}, Ghana`,
        },
      ],
    },
  };

  // 2. Pin to IPFS
  const cid = await this.pinataService.pinMetadata(metadata);
  const ipfsUri = this.pinataService.buildIpfsUri(cid);

  // 3. Mint on Lisk
  const { tokenId, txHash } = await this.blockchainService.mintHarvestToken(
    params.walletAddress,
    params.estimatedKg,
    ipfsUri
  );

  // 4. Store in DB
  await db.harvestToken.create({
    data: {
      farmerId,
      tokenIdOnChain: tokenId,
      epcisUri: ipfsUri,
      ipfsMetadataCid: cid,
      cropType: params.cropType,
      estimatedKg: params.estimatedKg,
      organicCertified: params.organicCertified,
      mintTxHash: txHash,
      isLocked: false,
    },
  });

  return { tokenId, cid, txHash };
}
```

---

## 🛑 Constraints

- **Never store sensitive farmer data in IPFS metadata** — IPFS is public. Only use wallet address (not name), GPS coordinates, and crop data.
- **Always upload before minting** — get the CID first, then call `HarvestToken.mint()` with the URI. Never mint with a placeholder URI.
- **CID is immutable** — If metadata must be updated (e.g., actual harvest kg vs estimate), mint a new token. The old token represents the original estimate.
- **Timeout handling** — Pinata API calls can be slow. Always use a 15-second timeout and retry on failure.

---

## ⚠️ Common Pitfalls

- **Metadata mismatch with contract:** The `uri(tokenId)` function in `HarvestToken.sol` must return `ipfs://{CID}` — ensure the format matches OpenSea and Lisk explorer standards.
- **PII in metadata:** National ID, encrypted name, or phone number must NEVER appear in IPFS metadata. It is publicly accessible.
- **Missing EPCIS fields:** Incomplete EPCIS events invalidate supply chain traceability. Always include at minimum a `planting` and `harvest_forecast` event.

---

## ✅ Acceptance Criteria

1. `PinataService.pinMetadata()` returns a valid IPFS CID for every call
2. `HarvestToken.uri(tokenId)` returns the correct `ipfs://{CID}` URL
3. Metadata JSON fetched from gateway matches the schema exactly
4. No PII (name, national ID, phone) appears in the IPFS metadata
5. Failed Pinata uploads are logged and do NOT result in a minted token
