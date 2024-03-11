import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";

import { timingSafeEqual } from "crypto";

const getCredentials = async (secretId) => {
  let credentials = null;

  try {
    const client = new SecretsManagerClient({ region: "us-east-1" });
    const command = new GetSecretValueCommand({
      SecretId: secretId,
    });

    const { SecretString } = await client.send(command);

    credentials = "Basic " + Buffer.from(SecretString).toString("base64");
  } catch (err) {
    console.error(err);
  }

  return credentials;
};

const getAuthHeader = (headers) =>
  headers.authorization ? headers.authorization[0].value : "";

const checkCredentials = async (input) => {
  let isValid = false;

  const credentials = await getCredentials("${BASIC_AUTH_SECRET_ID}");

  if (credentials) {
    const bufferCredentials = Buffer.from(credentials);
    const bufferInput = Buffer.from(input);

    try {
      isValid = timingSafeEqual(bufferCredentials, bufferInput);
    } catch (err) {
      console.error(err);
    }
  }

  return isValid;
};

export const handler = async (event, context, callback) => {
  const { request } = event.Records[0].cf;
  const { headers } = request;

  // Redirect from www.
  const host = headers.host ? headers.host[0].value : "";

  if (host.startsWith("www.")) {
    return callback(null, {
      status: 302,
      statusDescription: "Found",
      headers: {
        location: [
          {
            key: "Location",
            value: "https://" + host.slice(4) + request.uri,
          },
        ],
      },
    });
  }

  // Basic authentication
  const basicAuthEnabled = ${BASIC_AUTH_ENABLED};

  if (basicAuthEnabled) {
    const authHeader = getAuthHeader(headers);

    const validCredentials = await checkCredentials(authHeader);

    if (!validCredentials) {
      return callback(null, {
        body: "Unauthorized",
        headers: {
          "www-authenticate": [{ key: "WWW-Authenticate", value: "Basic" }],
        },
        status: "401",
        statusDescription: "Unauthorized",
      });
    }
  }

  return callback(null, request);
};
