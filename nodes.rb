module Nodes
  def block_content?(node)
    node.begin_type?
  end

  def html_el?(send_node)
    ruby_call(send_node) do |call|
      return false unless call[:ok]
      html_tags.include? call[:name]
    end
  end

  def render_file?(send_node)
    ruby_call(send_node) do |call|
      return false unless call[:ok]
      call[:name] == 'render'
    end
  end

  # @example node = `render "/admin/foo"`
  # @returns String e.g. "/admin/foo"
  def render_file(send_node)
    return nil unless render_file?(send_node)

    ruby_call(send_node) do |call|
      return false unless call[:ok]
      string(call[:args][0])
    end
  end

  def render_jsx?(send_node)
    ruby_call(send_node) do |call|
      return false unless call[:ok]
      call[:name] == 'react_component'
    end
  end

  def component?(send_node)
    ruby_call(send_node) do |call|
      return false unless call[:ok]
      components[:list].keys.include? call[:name].to_sym
    end
  end

  def lvasgn?(node)
    node.lvasgn_type?
  end

  def lvasgn(node)
    return nil unless lvasgn?(node)
    {
      var: node.children[0],
      expr: node.children[1]
    }
  end

  def ruby_call?(send_node)
    (send_node.children[1]).is_a?(Symbol) && send_node.children[0] == nil
  end

  def ruby_call(send_node)
    unless ruby_call? send_node
      res = { ok: false }
      yield res
      return false
    end

    res = { ok: true,
      name: send_node.children[1].to_s,
      args: send_node.children.slice(2, send_node.children.size - 1)
    }
    yield res
  end

  def jsx?(send_node)
    # todo
    # binding.pry
    render_jsx?(send_node) || html_el?(send_node) || component?(send_node)
  end

  def expr?(send_node)
    # todo
    # binding.pry
    false
  end

  def string?(node)
    node.str_type?
  end

  def string(node)
    return nil unless string?(node)
    node.children[0]
  end
end
