-- require Authorization request header
local auth_header = ngx.var.http_Authorization

if auth_header == nil then
    ngx.log(ngx.WARN, "No Authorization header")
    ngx.exit(ngx.HTTP_UNAUTHORIZED)
else
    ngx.log(ngx.INFO, "Authorization: " .. auth_header)

    -- require Bearer token
    local _, _, token = string.find(auth_header, "Bearer%s+(.+)")

    if token == nil then
        ngx.log(ngx.WARN, "Missing token")
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    else
        ngx.log(ngx.INFO, "Token: " .. token)
        return
    end
end
