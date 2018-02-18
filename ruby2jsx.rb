require 'singleton'
require 'pry'
require 'astrolabe/builder'
require 'parser/current'
require 'unparser'
require 'slim'
require 'snake_camel'

require './ruby2jsx_nodes'
include Nodes

def lower_camel(str)
  s = str.camelcase
  s[0].downcase + s[1..-1]
end

class PropsRegistry
  include Singleton
  def initialize
    @collection = {}
  end
  def add(name, ast_val)
    @collection[lower_camel(name)] = ast_val
  end
  def has(name)
    @collection.has_key? lower_camel(name)
  end
  def prop(name)
    @collection[lower_camel(name)]
  end
  def props
    @collection
  end
end

class Props
  include Singleton
  def initialize
    @reg = PropsRegistry.instance
  end

  def add_lvasgn(name, ast_val)
    @reg.add(name, ast_val)
  end

  def add_expr(ast_expr)
    if obj_prop?(ast_expr)
      add_obj_prop ast_expr

    elsif func_call?(ast_expr)
      add_func_call ast_expr

    else
      binding.pry
      # fixme
    end
  end

  def obj_prop?(expr)
    binding.pry
  end

  def func_call?(expr)
    binding.pry
  end

  def add_obj_prop(expr)
    binding.pry
  end

  def add_func_call(expr)
    binding.pry
  end

  def prop?(name)
    @reg.has name
  end
end

class PropsSrlzr
  include Singleton
  def initialize
    @reg = PropsRegistry.instance
  end

  def unparsed_prop(name)
    Unparser.unparse @reg.prop name
  end

  # prop_name => "ruby expr code"
  def to_ruby_hash
    unparsed_hash = {}
    @reg.props.each_key do |k|
      binding.pry
      unparsed_hash[k] = unparsed_prop k
    end
    unparsed_hash
  end
end

def props; @props ||= Props.instance; end
def props_s; @props_s ||= PropsSrlzr.instance; end

# @returns Node root_node
def parse(content)
  source_buffer = Parser::Source::Buffer.new('(string)')
  source_buffer.source = content

  ast_builder = Astrolabe::Builder.new
  parser = Parser::CurrentRuby.new(ast_builder)

  parser.parse(source_buffer)
end

def transpile(raw_node, level)
  # return transpile_block(node) if node.type == :block
  node, children, children_args = parse_node raw_node

  if Nodes.block_content?(node)
    # binding.pry

    children.
      map { |n| transpile(n, level + 1) }

  elsif Nodes.jsx?(node)
    # binding.pry
    is_container = children && children.length
    build_jsx_start(node) # None recursive

    if is_container
      children.map do |n|
        transpile n, level + 1 # Recursive
      end
    end

    build_jsx_end(node, is_container: is_container)

  elsif render_file?(node)
    # binding.pry
    path, ext = real_path render_file node
    content = File.read path
    if ext == :arb
      # binding.pry
      transpile(parse(content), level + 1) # Recursive
    elsif ext == :slim
      # binding.pry
      # todo: process slim and etc
      puts "/* slim_file #{ path }: \n#{ content }\n /slim_file */"
    else
      # binding.pry
      # todo
      puts "/* unkn_file #{ path }: \n#{ content }\n /unkn_file */"
    end

  elsif expr?(node)
    # binding.pry
    expr = node
    callback = children
    callback_args = children_args
    expr_str = build_expr(expr, callback, callback_args) # Recursive
    if html_el? node
      wrap_expr expr_str
    else
      expr_str
    end
  elsif lvasgn?(node)
    # todo: register using of external/local var
    # todo: create local var in some scope
    # todo: register prop
    # puts "const #{ lvasgn(node)[:camel] }"

    props.add_lvasgn(lvasgn(node)[:var].to_s, lvasgn(node)[:expr])
  else
    # binding.pry
    build_unknown(node, children, children_args)
  end
end

def build_jsx_start(node)
  # binding.pry
  # todo
  if Nodes.html_el?(node)
    # todo
  elsif Nodes.component?(node)
    # todo
  # ???
  elsif Nodes.render_jsx?(node)
    # todo
  end
end

def build_jsx_end(node, is_container:)
  # binding.pry
  # todo name = ...
  name = 'FooBar'

  if is_container
    puts "</#{ name }>"
  else
    puts '/>'
  end
end

def build_unknown(node, children, children_args)
  binding.pry
  puts "/* unk_node #{ node } /unk_node */"
  # node
  # todo raw code, location
end

def name_masks
  [
    lambda { |n| ["app/views/", "#{n}.arb", :arb]},
    lambda { |n| ["app/views/", "_#{n}.arb", :arb]},
    lambda { |n| ["app/views/", "_#{n}.slim", :slim]},
    lambda { |n| ["app/views/", "#{n}.slim", :slim]},
    lambda { |n| ["app/views/", "_#{n}.html.slim", :slim]},
    lambda { |n| ["app/views/", "#{n}.html.slim", :slim]}
  ].freeze
end

def real_path(path)
  # binding.pry
  dir_name = File.dirname path
  base_name = File.basename path

  real_path = nil
  ext = nil
  name_masks.each do |mask|
    root_dir, probe_name, ext = mask.call(base_name)
    probe_path = File.join(root_dir, dir_name, probe_name)
    real_path = probe_path if File.exist? probe_path
  end
  [real_path, ext]
end

def wrap_expr(expr_str)
  # binding.pry
  if expr_str.length > 70
    puts "{\n#{ indent(expr_str) }\n}"
  else
    puts "{ #{ expr_str } }"
  end
end

def indent(str, base = 0)
  # binding.pry
  str.
    split("\n").
    map { |s| "#{ Array.new(base).fill(' ') }  #{ s }" }.
    join("\n")
end

def html_tags
  [
    'div',
    'span',
    'a',
    'br',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'i',
    'form_to',
    'strong'
    # todo: complete
  ].freeze
end

def components
  { defaults: { path: 'components/common/' }.freeze, list: {
    'attributes_table_for' => { name: 'Attrs' },
    'row' => { name: 'Attrs.Row' },
    'table_for' => { name: 'Table' },
    'columns' => { name: 'Columns' },
    'column' => lambda do |parent|
      {
        'table_for' => { name: 'Table.Col' },
        'columns' => { name: 'Columns.Col' }
      }[parent]
    end,
    'panel' => { name: 'Panel' },
    'link_to' => { name: 'Link' },
    'button_to' => { name: 'Button' },
    'best_in_place' => { name: 'BestInPlace' },
    'i' => lambda { |parent, node| todo }
    # plastic_link_to
    # account_link_to
    # smart_link_to
    # todo: complete
  }.freeze}.freeze
end

def prop_map
  {
    'class' => 'className'
    # todo: complete
  }.freeze
end

def parse_node(node)
  if node.type == :block
    [node.children[0], node.children[2].children, node.children[1].children]
  else
    [node, node.children, nil]
  end
end

transpile (parse File.read ARGV[0]), 0

# # cases: 1) jsx children 2) map callbacks 3) ???
# def transpile_block (node)
#   # is_tag = html_el? node.children[0]

#   children = if container_?
#     node.children.map do |n|
#       transpile n
#     end
#   end

#   transpile_node node.children[0]
#   wrap children, is_container: true

# end


# TODO:
# - how to detect local and external variables
#   - expressions on external variables to props
#


# s(:block,   # call with block
#   s(:send, nil, :columns), # call name
#   s(:args), # | |
#   s(:begin, # do

# ...
#   s(:args,
#     s(:arg, :b)), # | b |

# ...
#   s(:str, "Сколько") # "Сколько"

# ...
#   s(:send, nil, :call_name, s(:str, "Сколько")) # call_name "Сколько"

# ...
#   s(:hash,
#     s(:pair, s(:str, "data-role"), s(:str, "duration"))
#   ) # { "data-role" => "duration" }

# ...
# s(:sym, :collection) # :collection

# ...
# s(:array,
#   s(:lvar, :k),
#   s(:lvar, :v)) # [ k, v ]

# s(:if, # if
#   s(:or, a, b), # a || b
#   # then
#   a,
#   b
# )

# s(:lvasgn, :var, s(:str, "123")) # var = "123"

# s(:send,
#   :attributes,
#   :[],
#   s(:str, "hard_scheduled")
# ) # attributes["hard_scheduled"]

# s(:dstr,
#   s(:str, "foo-"),
#   s(:begin, s(:lvar, :bar))
# ) # "foo-#{ bar }"
