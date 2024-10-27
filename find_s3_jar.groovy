def s3_path = "s3://${s3_bucket}/${service_name}/"
def aws_s3_ls_output = "aws s3 ls ${s3_path}".execute() | ['awk', '{ print $NF }'].execute()
aws_s3_ls_output.waitFor() 
def files = aws_s3_ls_output.text.tokenize().reverse()
def result = []
result.addAll(files)
return result