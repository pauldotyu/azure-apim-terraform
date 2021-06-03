using System.Collections.Generic;
using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace Hello.Function
{
    public static class HelloImage
    {
        [Function("HelloImage")]
        public static HttpResponseData Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req,
            FunctionContext executionContext)
        {
            var logger = executionContext.GetLogger("HelloImage");
            logger.LogInformation("C# HTTP trigger function processed a request.");

            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "text/plain; charset=utf-8");

            if (req.Method == "POST")
            {
                response.WriteString("Welcome to Azure Functions! The posted image is " + req.Body.Length.ToString());
            }
            else
            {
                response.WriteString("Welcome to Azure Functions! You are getting " + req.Url);
            }
            //https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.functions.worker.http.httprequestdata?view=azure-dotnet
            return response;
        }
    }
}
