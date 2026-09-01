-- shaders.lua — pixel shaders for sprite effects (outline + flash).
--
-- Instead of pre-baking an outline or a white "flash" variant into the sheet,
-- both are computed at draw time from the sprite's alpha channel:
--   * outline: 1px border drawn where alpha goes to 0 (configurable color)
--   * flash:   white wash that keeps the sprite silhouette
-- This keeps the sheet smaller and makes the effect trivially tweakable.

local shaders = {}

local SHADER_SRC = [[
  extern vec4 OutlineColor;
  extern vec4 FlashColor;
  extern float OutlineWidth;   // in texels
  extern float FlashAmount;    // 0..1

  vec4 effect(vec4 color, Image texture, vec2 texPos, vec2 screenPos) {
    vec4 tex = Texel(texture, texPos);
    float alpha = tex.a;

    // Outline: sample up to OutlineWidth texels in 4/8 directions; if the
    // current pixel is transparent but a neighbour is opaque, draw outline.
    if (alpha < 0.5) {
      vec2 step = OutlineWidth / love_ScreenSize.xy;
      for (int i = 1; i <= 4; ++i) {
        vec2 d = step * float(i);
        if (Texel(texture, texPos + vec2(d.x, 0.0)).a > 0.5 ||
            Texel(texture, texPos + vec2(-d.x, 0.0)).a > 0.5 ||
            Texel(texture, texPos + vec2(0.0, d.y)).a > 0.5 ||
            Texel(texture, texPos + vec2(0.0, -d.y)).a > 0.5) {
          alpha = 1.0;
          tex = OutlineColor;
          break;
        }
      }
    }

    // Flash: blend towards a flat white, keeping the silhouette alpha.
    vec3 flashed = mix(tex.rgb, FlashColor.rgb, FlashAmount);
    float fa = mix(alpha, FlashColor.a, FlashAmount);

    return vec4(flashed, fa) * color;
  }
]]

shaders.sprite = love.graphics.newShader(SHADER_SRC)

shaders.default = {
  outline = { 0.02, 0.03, 0.06, 1 },
  flash   = { 1, 1, 1, 1 },
  width   = 1,
  amount  = 0,
}

-- Sends outline/flash uniforms for the next sprite draw.
function shaders.set(outline, flash, width, amount)
  local s = shaders.sprite
  local o = outline or shaders.default.outline
  local f = flash or shaders.default.flash
  s:send("OutlineColor", { o[1], o[2], o[3], o[4] or 1 })
  s:send("FlashColor", { f[1], f[2], f[3], f[4] or 1 })
  s:send("OutlineWidth", width or shaders.default.width)
  s:send("FlashAmount", amount or shaders.default.amount)
end

-- Shortcuts used by the renderer.
function shaders.outline(color)
  shaders.set(color, nil, 1, 0)
end

function shaders.flash(color, amount)
  shaders.set(nil, color, 1, amount or 1)
end

function shaders.none()
  shaders.set()
end

return shaders