local jwt = require "resty.jwt"
local cjson = require "cjson"
local basexx = require "basexx"
local secret = os.getenv("JWT_SECRET")

assert(secret ~= nil, "Environment variable JWT_SECRET not set")

if os.getenv("JWT_SECRET_IS_BASE64_ENCODED") == 'true' then
    -- convert from URL-safe Base64 to Base64
    local r = #secret % 4
    if r == 2 then
        secret = secret .. "=="
    elseif r == 3 then
        secret = secret .. "="
    end
    secret = string.gsub(secret, "-", "+")
    secret = string.gsub(secret, "_", "/")

    -- convert from Base64 to UTF-8 string
    secret = basexx.from_base64(secret)
end

local M = {}

function M.auth()
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

            -- require valid JWT
            local jwt_obj = jwt:verify(secret, token)
            if jwt_obj.verified == false then
                ngx.log(ngx.WARN, "Invalid token: ".. jwt_obj.reason)
                ngx.exit(ngx.HTTP_UNAUTHORIZED)
            else
                ngx.log(ngx.INFO, "JWT: " .. cjson.encode(jwt_obj))

                -- write the X-Auth-UserId header
                ngx.header["X-Auth-UserId"] = jwt_obj.payload.sub
                return
            end
        end
    end
end

function M.table_contains(table, item)
    for key, value in pairs(table) do
        if value == item then return true end
    end
    return false
end

return M
