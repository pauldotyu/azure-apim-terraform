using System.Collections;
using System.Collections.Generic;
using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace HelloFunction
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
                string name = string.Empty;
                try
                {
                    Hashtable qs = new();
                    foreach (string q in req.Url.PathAndQuery.Split('?')[1].Split('&'))
                    {
                        string[] kv = q.Split('='); // element 0 is a key, element 1 is a value
                        qs.Add(kv[0], kv[1]); 
                    }

                    name = qs["name"].ToString();
                }
                catch (System.Exception)
                {
                    name = "nothing";
                }
                
                response.WriteString("Welcome to Azure Functions! You are getting " + name);
            }
            //https://docs.microsoft.com/en-us/dotnet/api/microsoft.azure.functions.worker.http.httprequestdata?view=azure-dotnet
            return response;
        }
    }
}
