import {
  CodePipelineClient,
  StartPipelineExecutionCommand,
} from "@aws-sdk/client-codepipeline";

export const handler = async () => {
  try {
    const codepipelineIds = JSON.parse(process.env.CODEPIPELINE_IDS);
    const client = new CodePipelineClient();
    const errors = {};

    for (const id of codepipelineIds) {
      try {
        const input = {
          name: id,
        };

        console.log(`Starting execution of pipeline: ${id}`);
        const command = new StartPipelineExecutionCommand(input);
        await client.send(command);
        console.log(`Pipeline successfully executed: ${id}`);
      } catch (err) {
        errors[id] = err.message;
      }
    }

    if (Object.keys(errors).length) {
      let errorMessage = "";
      for (const err of Object.entries(errors)) {
        errorMessage += `${err[0]}: ${err[1]}\n`;
      }

      console.log(errorMessage);
      return {
        statusCode: 400,
        body: errorMessage,
      };
    }

    return {
      statusCode: 200,
      body: "OK",
    };
  } catch (err) {
    console.log(err);
    return {
      statusCode: 400,
      body: err.message,
    };
  }
};
