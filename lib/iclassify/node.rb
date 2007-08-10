require 'rubygems'
require 'rexml/document'
require 'builder'
require 'yaml'

module IClassify
  class Node
    attr_accessor :tags, :uuid, :description, :notes, :attribs, :node_id
    
    def initialize(xml=nil)
      from_xml(xml) if xml
      @tags ||= Array.new
      @attribs ||= Array.new
    end
    
    def to_xml
      xml = Builder::XmlMarkup.new
      output = xml.node do
        xml.id(@node_id) if @node_id
        xml.uuid(@uuid)
        xml.description(@description)
        xml.notes(@notes)
        xml.tags do
          @tags.sort.each do |tag|
            xml.tag(tag)
          end
        end
        xml.attribs do
          @attribs.sort{ |a,b| a[:name] <=> b[:name] }.each do |attrib|
            xml.attrib do
              xml.name(attrib[:name])
              xml.values do
                attrib[:values].each do |v|
                  xml.value(v)
                end
              end
            end
          end
        end
      end
      output
    end
    
    def to_s(tags=nil,attribs=nil)
      output = String.new
      output << "uuid: #{@uuid}\n"
      output << "node_id: #{@node_id}\n"
      output << "notes: #{@notes}\n"
      output << "description: #{@description}\n"
      output << "tags: #{@tags.sort.join(' ')}\n"
      output << "attribs:\n"
      @attribs.sort{ |a,b| a[:name] <=> b[:name] }.each do |attrib|
        output << "  #{attrib[:name]}: #{attrib[:values].join(', ')}\n"
      end
      output
    end
    
    def to_puppet
      output = Hash.new
      output["classes"] = @tags
      output["parameters"] = Hash.new
      @attribs.each do |attrib|
        if attrib[:values].length > 1
          output["parameters"][attrib[:name]] = attrib[:values]
        else
          output["parameters"][attrib[:name]] = attrib[:values][0]
        end
      end
      output.to_yaml
    end
        
    def from_xml(doc)
      xml = nil
      if doc.kind_of?(REXML::Element)
        xml = doc
      else
        xml = REXML::Document.new(doc)
      end
      @tags = Array.new
      xml.elements.each('//tag') { |t| @tags << t.text }
      @uuid = xml.get_text('//uuid')
      @node_id   = xml.get_text('//id')
      @description = xml.get_text('//description')
      @notes = xml.get_text('//notes')
      @attribs = Array.new
      xml.elements.each('//attrib') do |attrib|
        cattrib = Hash.new
        cattrib[:name] = attrib.get_text('name').to_s
        value_array = Array.new
        attrib.elements.each('values/value') { |v| value_array << v.text }
        cattrib[:values] = value_array 
        @attribs << cattrib
      end
    end
      
  end
end
