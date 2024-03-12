import {
  CloudFrontClient,
  CreateInvalidationCommand,
} from "@aws-sdk/client-cloudfront";
import {
  CodePipelineClient,
  PutJobFailureResultCommand,
  PutJobSuccessResultCommand,
} from "@aws-sdk/client-codepipeline";

const createCloudFrontInvalidation = async (jobId, distributionId) => {
  const client = new CloudFrontClient();

  const input = {
    DistributionId: distributionId,
    InvalidationBatch: {
      Paths: {
        Quantity: 1,
        Items: ["/*"],
      },
      CallerReference: jobId,
    },
  };

  const command = new CreateInvalidationCommand(input);
  const response = await client.send(command);

  return response;
};

const putCodePipelineResult = async (jobId, invalidationId) => {
  const client = new CodePipelineClient();
  const input = { jobId };
  let command;

  if (invalidationId) {
    command = new PutJobSuccessResultCommand(input);
  } else {
    command = new PutJobFailureResultCommand(input);
  }

  await client.send(command);
};

export const handler = async (event) => {
  const { id: jobId } = event["CodePipeline.job"];
  let invalidationId;

  try {
    const distributionId = process.env.CLOUDFRONT_DISTRIBUTION_ID;
    const response = await createCloudFrontInvalidation(jobId, distributionId);
    invalidationId = response.Invalidation?.Id;
  } catch (err) {
    console.error(err);
  }

  await putCodePipelineResult(jobId, invalidationId);
};
