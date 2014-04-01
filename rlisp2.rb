require 'cmath'
class Env < Hash
    def initialize(keys=[],vals=[],outer=nil)
        @outer=outer
        #zip返回list,每个元素为一个pair，所以需要手动转换，和python不太一样
        keys.zip(vals).each{|p| store(*p)}
        #dup.update(keys.zip(vals))
    end
    def [](name) super(name)||@outer[name] end
    def set(name,val) key?(name) ? store(name,val): @outer.set(name,val) end
end
class Procedure
    def initialize(parms,exp,env)
        @parms,@exp,@env=parms,exp,env
    end
end

def add_globals(env)
    #添加操作符和运算符
    ops=[:+,:-,:*,:/, :>, :<, :>=, :<=, :==]
    ops.each{|op| 
        env[op]=lambda{|a,b| a.method(op).call(b)}
    }
    Math.methods(false).each{|k| env[k]=Math.method(k)}
    CMath.methods(false).each{|k| env[k]=CMath.method(k)}
    env.update({:length => lambda{|x| x.length}, :cons => method(:cons),:car => lambda{|x| x[0]},:cdr => lambda{|x| x[1..-1]}, :append => lambda{|x,y| x+y},
  :list => lambda{|*xs| xs}, :list? => lambda{|x| x.is_a? Array}, :null? => lambda{|x| x==nil},
  :symbol? => lambda{|x| x.is_a? Symbol}, :not => lambda{|x| !x}, :display1 => lambda{|x| p x},'boolean?'=>lambda{|x| !!x==x},'pair?'=>method(:is_pair),'port?'=>lambda{|x| x.is_a? File},'apply'=>lambda{|p,l| p.call(*l)},'eval'=>lambda{|x| eval(expand(x))},'load'=>lambda{|fn| load(fn)},'open-input-file'=>method(:open),'close-input-port'=>lambda{|p| p.file.close},'open-output-file'=>lambda{|f| opne(f,'w')},'close-output-port'=>lambda {|p| p.close()},
     'eof-object?'=>lambda {|x| x.eof}, 'read-char'=>method(:readchar),
     'read'=>method(:read), 'write'=>lambda{|x| port=STDOUT.write(to_string(x))},
     'display'=>lambda{|x| port=$stdout.write((x.is_a?String)? x : x.to_s)}})

end
def read
end
def readchar
end
def is_pair(x) x!=[] and x.is_a? Array end
def cons(x,y) [x]+y end


def eval(x,env)
    return env[x] if x.is_a? Symbol     #表示是个变量
    return x if !x.is_a? Array           #是个数组，就是lisp中的list
    case x[0]
    when :quote         #(quote exp)
        x[1..-1]
    when :if            #(if test conseq alt) 
        _,test,conseq,alt=x
        eval(eval(test,env) ? conseq : alt,env)     #获取test的结果
    when :set!          #(set! var exp) set表示了变量已经存在的情况
        _,var,exp=x
        env.set(var,eval(exp,env))
    when :define        #(define var exp)
        _,var,exp=x
        env[var]=eval(exp,env)
    when :lambda        #(lambda (var*) exp)
        _,vars,exp=x
        #创建一个过程
        Proc.new{|*args| eval(exp,Env.new(vars,args,env))}
    when :begin         #(begin exp*)
        val=nil
        x[1..-1].each{|exp|
            val=eval(exp,env)
        }
        return val
    else                #(proc exp*)
        exps=x.map{|exp| eval(exp,env)}
        exps[0].call(*exps[1..-1])
        
    end
end
def parseport(inport)
    if inport.is_a? String then inport=InPort(StringIO.new(inport)) end
    return expand(read(inport,toplevel=true))
end

def expand(x,toplevel=true)
    assert(x,x!=[])
    return x if !x.is_a? Array
    case x[0]
    when :quote         #(quote exp)
        assert(x,x.length==2)
        reutrn x
    when :if            #(if test conseq alt) 
        x+=[nil] if x.length==3
        assert(x,x.length==4)
        return map(expand,x)
    when :set!          #(set! var exp) set表示了变量已经存在的情况
        assert(x,x.length==3)
        var=x[1]
        assert(x,var.is_a?Symbol)
        [:set,var,expand(x[2])]    
    when :define        #(define var exp)
        _,var,exp=x
        env[var]=eval(exp,env)
    when :lambda        #(lambda (var*) exp)
        _,vars,exp=x
        #创建一个过程
        Proc.new{|*args| eval(exp,Env.new(vars,args,env))}
    when :begin         #(begin exp*)
        val=nil
        x[1..-1].each{|exp|
            val=eval(exp,env)
        }
        return val
    else                #(proc exp*)
        exps=x.map{|exp| eval(exp,env)}
        exps[0].call(*exps[1..-1])
        
    end

end
def assert(x, predicate, msg="wrong length")
    "Signal a syntax error if predicate is false."
    if not predicate
        raise SyntaxError(x.to_s+': '+msg)
    end
end
def loadfile(fn)
    reql(nil,InPort.new(open(fn)),nil)
end
class InPort
    def initialize(file)
        @file=file;
        @line=''
    end
    def next_token
    end
end
def atom(s)
    #还没看明白
    return "[" if s=='('  
    return "]" if s==')'  
    return s if s =~ /^-?\d+$/ || s =~ /^-?\d*\.\d+$/    #数值转换
    ':'+s   #当为字符串的时候直接输出
    
end

#词法分析
def parse(s)
    toks=s.gsub('(',' ( ').gsub(')',' ) ').split
    Kernel.eval(toks.map{|s| atom(s)}.join(' ').gsub(' ]',']').gsub('[ ','[').gsub(/([^\[]) /,'\1, '))
    
end
src =<<CODE  
(begin  
 (define fact (lambda (n)   
  (if (<= n 1) 1 (* n (fact (- n 1))))))  
   
 (fact 5)  
)  
CODE
keys = [1, 2, 3]
vals = ["a", "b", "c"]
env=Env.new
add_globals(env)
#p env
p (eval(parse("(log 2)"),env))
#keys=CMath.methods(false)
#p (keys.zip(keys.map{|k| CMath.method(k)}))
#p (eval(parse(src),env))
