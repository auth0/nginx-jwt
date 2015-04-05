local auth_header = ngx.var.http_Authorization

if auth_header == nil then
    ngx.log(ngx.STDERR, "No Authorization header")
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
else
    ngx.log(ngx.STDERR, "Authorization: " .. auth_header)

    local _, _, token = string.find(auth_header, "Bearer%s+(.+)")

    if token == nil then
        ngx.log(ngx.STDERR, "Missing token")
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    else
        ngx.log(ngx.STDERR, "Token: " .. token)
        return
    end
end
