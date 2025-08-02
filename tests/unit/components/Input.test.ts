import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Input from '../../../gli_user-frontend/src/components/ui/Input/Input.vue'

describe('Input', () => {
  it('기본 렌더링', () => {
    const wrapper = mount(Input, { props: { placeholder: '입력하세요' } })
    const input = wrapper.find('input')
    expect(input.exists()).toBe(true)
    expect(input.attributes('placeholder')).toBe('입력하세요')
  })

  it('disabled prop이 적용된다', () => {
    const wrapper = mount(Input, { props: { disabled: true } })
    const input = wrapper.find('input')
    expect(input.attributes('disabled')).toBeDefined()
  })
})
