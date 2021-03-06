//
//  Typealias.swift
//  MemoryChainKit
//
//  Created by Marc Steven on 2020/3/15.
//  Copyright © 2020 Marc Zhao(https://github.com/MarcSteven). All rights reserved.
//

import UIKit

public typealias CompletionHandler = () -> Void
public typealias JSON = [String:Any]

public typealias JSONArray = [Any]


public typealias View = UIView

public typealias ResponseHandler = (Data?,URL?,URLResponse?)


public typealias UpdatableCell = Updatable & UITableViewCell
