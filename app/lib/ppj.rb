# frozen_string_literal: true

def ppj(*args)
  args.each do |o|
    o.is_a?(Hash) ? puts(JSON.pretty_generate(o)) : pp(o)
  end
end
