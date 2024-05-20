# Vocap

## 🛠️ 기술 스택
* UIKit
* MVC
* Realm
* SPM
* Storyboard

## 🧑‍💻 주요 기능
* 로컬 데이터 저장
* 카테고리별 단어 관리
* 배경 화면을 터치하여 단어 생성/수정
* 의미를 입력할 때 한글 키보드로 자동 변경
* 여러개의 단어를 한번에 삭제하거나 다른 카테고리로 이동
* 단어 상세 페이지에서 예문 추가
* 단어 검색
* 현재 단어/선택된 단어 개수 표시

## 📝 구현 내용
### 1. 카테고리 생성/수정/삭제
![SimulatorScreenRecording-iPhone11ProMax-2024-05-10at11 52 08-ezgif com-resize](https://github.com/devjuhyun/Vocap/assets/117050638/37d8a243-8815-4066-89b0-3097d1083324)

* UIAlertController를 사용하여 카테고리 생성/수정/삭제 구현
```swift
func presentAlert() {
    var textField = UITextField()

    let alert = UIAlertController(title: title, message: "", preferredStyle: .alert)

    let save = UIAlertAction(title: "확인", style: .default) { UIAlertAction in
        // save category
    }

    let cancel = UIAlertAction(title: "취소", style: .cancel)

    alert.addTextField { UITextField in
        textField = UITextField
        textField.placeholder = "Name"
    }

    alert.addAction(save)
    alert.addAction(cancel)

    present(alert, animated: true)
}
```
* UITableView의 trailingSwipeActionsConfigurationForRowAt 메서드를 활용하여 카테고리 수정/삭제 스와이프 버튼 구현
```swift
override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    let delete = UIContextualAction(style: .normal, title: "delete") { (UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
        // delete category
        success(true)
    }
    let edit = UIContextualAction(style: .normal, title: nil) { ( UIContextualAction, UIView, success: @escaping (Bool) -> Void) in
        // edit category
        success(true)
    }

    delete.backgroundColor = .red
    delete.image = UIImage(systemName: "trash.fill")

    edit.backgroundColor = .orange
    edit.image = UIImage(systemName: "pencil")
    edit.title = "Rename"

    return UISwipeActionsConfiguration(actions:[delete, edit])
}
```

### 2. 단어 추가
![word1](https://github.com/devjuhyun/Vocap/assets/117050638/949e07d9-7744-476d-9fa8-eff89df8cd42)
* UITapGestureRecognizer를 사용하여 UITableView의 배경 터치를 감지하고 새로운 단어 추가
	* 터치된 위치의 indexPath가 nil일 경우 테이블 뷰의 배경인 점을 이용
```swift
@objc func tableTapped(tap:UITapGestureRecognizer) {
    let location = tap.location(in: self.tableView)
    let path = self.tableView.indexPathForRow(at: location)

    if path == nil {
        if addBtn.isHidden {
            deleteEmptyCell()
        } else {
            addNewVocab()
        }
    }
}
```
* UITextField의 tag 프로퍼티를 이용하여 텍스트 필드에서 return버튼을 눌렀을 때 의미를 입력하는 텍스트 필드로 이동할지, 새로운 단어를 추가할지, 단어 추가를 취소할지를 결정하는 로직 구현
```swift
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "VocabCell", for: indexPath) as! VocabularyCell
    /* ... */
    cell.vocabTextField.tag = indexPath.row * 2
    cell.meaningTextField.tag = cell.vocabTextField.tag + 1
    /* ... */
}

func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    let tag = textField.tag
    let row = tag / 2 // indexPath.row

    guard let cell = textField.superview?.superview as? VocabularyCell else { fatalError() }

    if tag % 2 == 0 { // 단어 텍스트 필드인 경우
        if textField.text == "" { // 텍스트가 비어있으면
            textField.endEditing(true) // 편집 종료
            deleteVocabularies(at: row) // 현재 단어 삭제
        } else { // 비어있지 않으면
            cell.meaningTextField.becomeFirstResponder() // 셀의 단어 텍스트 필드로 이동
        }
    } else { // 의미 텍스트 필드인 경우
        guard let vocabularies = vocabularies?.count else { fatalError() } // 단어 개수
        let indexPath = IndexPath(row: row + 1, section: 0) // 다음 셀 indexPath

        if row < vocabularies - 1 { // 테이블 뷰 중간에 있는 셀인 경우
            let nextCell = tableView.cellForRow(at: indexPath) as! VocabularyCell
            nextCell.vocabTextField.becomeFirstResponder() // 다음 셀의 단어 텍스트 필드로 이동
        } else { // 마지막 셀인 경우
            addNewVocab() // 새로운 단어 추가
        }
    }

    return true
}
```
* Callback을 사용하여 셀의 텍스트 필드에 입력된 텍스트를 받아서 단어 업데이트
* CustomTextField를 만들어서 단어의 의미를 입력하는 텍스트필드가 first responder가 될시 키보드 언어를 한글로 변경하는 기능 구현
```swift
class CustomTextField: UITextField {
    var language:String = "ko-KR"

    override var textInputMode: UITextInputMode? {
            for inputMode in UITextInputMode.activeInputModes {
                if inputMode.primaryLanguage! == language {
                    return inputMode
                }
        }
        return super.textInputMode
    }
}
```
* Toolbar에 현재 단어의 개수를 표시하는 기능 구현

### 3. 단어 검색
![wordsearch](https://github.com/devjuhyun/Vocap/assets/117050638/de26fd93-1e38-4e73-873e-d277699d9c76)

* NSPredicate을 사용한 단어 필터링
```swift
func updateSearchResults(for searchController: UISearchController) {
    guard let text = searchController.searchBar.text else { return }

    filteredVocabularies = vocabularies?.filter("vocab CONTAINS[cd] %@", text).sorted(byKeyPath: "vocab", ascending: true)

    tableView.reloadData()
}
```
* isFiltering 변수로 단어 업데이트
	* search controller의 isActive가 true이고 searchBar의 text가 비어있지 않을 경우에만 true를 반환하는 computed property
```swift
var isFiltering: Bool {
    let searchController = self.navigationItem.searchController
    let isActive = searchController?.isActive ?? false
    let isSearchBarHasText = searchController?.searchBar.text?.isEmpty == false

    return isActive && isSearchBarHasText
}
```

### 4. 단어 편집

| ![movewords](https://github.com/devjuhyun/Vocap/assets/117050638/ed563554-5b96-4fe3-b58a-4809cf9f4995) | ![deletewords](https://github.com/devjuhyun/Vocap/assets/117050638/758ed896-605e-404c-9145-f5f6f5da309d) |
| :----------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------------------------------: |
|                                                 단어 이동                                                  |                                                  단어 삭제                                                   |

* UITableView의 setEditing 메서드를 사용하여 편집 모드로 전환
* UITableView의 indexPathsForSelectedRows 속성을 이용하여 선택된 단어를 다른 카테고리로 이동
* 스와이프하여 단어를 삭제하거나 편집 모드에서 여러개의 단어를 선택하여 삭제하는 기능을 구현

## 🧑‍🔧 문제점 개선
### 1. 단어 상세 페이지에서 수정된 단어가 반영되지 않는 이슈
* DetailViewController에서 단어의 정보를 변경했을때 VocabulariesViewController에 변경된 정보가 바로 반영되지 않는 문제를 발견
* DetailViewController안에서 UINavigationController를 통해 VocabulariesViewController의 인스턴스에 접근하여 reloadData 메서드를 호출하여 해결

```swift
override func viewWillDisappear(_ animated: Bool) {  
	super.viewWillDisappear(animated)  
  
	if let navVC = presentingViewController as? UINavigationController {  
		if let firstVC = navVC.viewControllers[1] as? VocabulariesViewController {  
			firstVC.tableView.reloadData()  
		}  
	}  
}
```

### 2.  단어 이동시 생기는 이슈
* 선택한 단어를 이동할때 현재 카테고리의 선택된 단어들을 모두 삭제한 뒤 이동할 카테고리에 선택된 단어들을 추가하는 방식으로 구현했으나 현재 카테고리의 단어들이 이상하게 삭제되는 것을 발견
* 선택된 단어들을 하나씩 삭제할때마다 인덱스가 변경되기때문에 생기는 문제인 것을 파악 후 remove(atOffsets:) 메서드를 사용하여 해결

```swift
override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {  
	if let cell = tableView.cellForRow(at: indexPath) {  
		if cell.textLabel?.textColor != .darkGray {  
			try! realm.write {  
				if let indexs = indexs { // indexs: 선택된 단어들의 index를 가지고 있는 옵셔널 Int 배열
					let indexSet = IndexSet(indexs)  
					selectedCategory?.vocabs.remove(atOffsets: indexSet)  
				}  
				  
				if let selectedVocabs {  
					categories?[indexPath.row].vocabs.append(objectsIn: selectedVocabs)  
				}  
			}  
			navigationController?.dismiss(animated: true)  
		}  
	}  
}
```
