```rb
# cases: 1) jsx children 2) map callbacks 3) ???
def transpile_block (node)
  # is_tag = html_el? node.children[0]

  children = if container_?
    node.children.map do |n|
      transpile n
    end
  end

  transpile_node node.children[0]
  wrap children, is_container: true

end


TODO:
- how to detect local and external variables
  - expressions on external variables to props
#


s(:block,   # call with block
  s(:send, nil, :columns), # call name
  s(:args), # | |
  s(:begin, # do

...
  s(:args,
    s(:arg, :b)), # | b |

...
  s(:str, "Сколько") # "Сколько"

...
  s(:send, nil, :call_name, s(:str, "Сколько")) # call_name "Сколько"

...
  s(:hash,
    s(:pair, s(:str, "data-role"), s(:str, "duration"))
  ) # { "data-role" => "duration" }

...
s(:sym, :collection) # :collection

...
s(:array,
  s(:lvar, :k),
  s(:lvar, :v)) # [ k, v ]

s(:if, # if
  s(:or, a, b), # a || b
  # then
  a,
  b
)

s(:lvasgn, :var, s(:str, "123")) # var = "123"

s(:send,
  :attributes,
  :[],
  s(:str, "hard_scheduled")
) # attributes["hard_scheduled"]

s(:dstr,
  s(:str, "foo-"),
  s(:begin, s(:lvar, :bar))
) # "foo-#{ bar }"
```
